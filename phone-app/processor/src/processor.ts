import * as fs from 'fs';
import * as path from 'path';
import { XMLParser } from 'fast-xml-parser';
import * as turf from '@turf/turf';
import { Feature, FeatureCollection, LineString, BBox } from 'geojson';

interface FeatureProperties {
    status: 'untraveled' | 'traveled' | 'unpaved' | 'achievement' | 'unknown';
    originalStyle: string;
}

const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: "@_"
});

function parseCoordinates(coordString: string): number[][] {
    return coordString.trim().split(/\s+/).map(pair => {
        const [lon, lat] = pair.split(',').map(Number);
        return [lon, lat];
    });
}

function getStatusFromStyle(styleUrl: string): FeatureProperties['status'] {
    if (styleUrl.includes('UntraveledUnpaved')) return 'unpaved';
    if (styleUrl.includes('Untraveled')) return 'untraveled';
    if (styleUrl.includes('Traveled')) return 'traveled';
    if (styleUrl.includes('achievementBoundary')) return 'achievement';
    return 'unknown';
}

export function convertKmlToGeoJson(kmlPath: string): FeatureCollection<LineString, FeatureProperties> {
    const kmlContent = fs.readFileSync(kmlPath, 'utf-8');
    const jsonObj = parser.parse(kmlContent);
    
    if (!jsonObj.kml || !jsonObj.kml.Document) {
        throw new Error("Invalid KML structure: missing Document");
    }

    const placemarks = jsonObj.kml.Document.Placemark;
    const features: Feature<LineString, FeatureProperties>[] = [];

    const placemarkArray = Array.isArray(placemarks) ? placemarks : [placemarks];

    for (const pm of placemarkArray) {
        if (!pm) continue;
        const styleUrl = pm.styleUrl || '';
        const status = getStatusFromStyle(styleUrl);
        const properties: FeatureProperties = { status, originalStyle: styleUrl };

        if (pm.LineString) {
            const coords = parseCoordinates(pm.LineString.coordinates);
            if (coords.length > 1) {
                features.push(turf.lineString(coords, properties) as Feature<LineString, FeatureProperties>);
            }
        } else if (pm.MultiGeometry && pm.MultiGeometry.LineString) {
            const lineStrings = Array.isArray(pm.MultiGeometry.LineString) 
                ? pm.MultiGeometry.LineString 
                : [pm.MultiGeometry.LineString];
            
            for (const ls of lineStrings) {
                const coords = parseCoordinates(ls.coordinates);
                if (coords.length > 1) {
                    features.push(turf.lineString(coords, properties) as Feature<LineString, FeatureProperties>);
                }
            }
        }
    }

    return turf.featureCollection(features) as FeatureCollection<LineString, FeatureProperties>;
}

export function tileGeoJson(geojson: FeatureCollection<LineString, FeatureProperties>, zoom: number, outputDir: string) {
    console.log(`Tiling at zoom level ${zoom}...`);
    
    geojson.features.forEach((feature) => {
        if (!feature.geometry || feature.geometry.type !== 'LineString') return;

        const bbox = turf.bbox(feature) as BBox;
        const minTile = lonLatToTile(bbox[0], bbox[3], zoom);
        const maxTile = lonLatToTile(bbox[2], bbox[1], zoom);

        for (let x = minTile.x; x <= maxTile.x; x++) {
            for (let y = minTile.y; y <= maxTile.y; y++) {
                const tileBbox = tileToBbox(x, y, zoom);
                const tilePoly = turf.bboxPolygon(tileBbox);
                
                try {
                    // In Turf v7, some boolean operators are directly on the turf object
                    // but sometimes types are weird. Using (turf as any) to bypass strict type check if needed
                    if ((turf as any).booleanIntersects(feature, tilePoly)) {
                        const tilePath = path.join(outputDir, `${zoom}/${x}/${y}.json`);
                        ensureDirectoryExistence(tilePath);
                        
                        let tileData: any = { features: [] };
                        if (fs.existsSync(tilePath)) {
                            tileData = JSON.parse(fs.readFileSync(tilePath, 'utf-8'));
                        }
                        
                        tileData.features.push(feature);
                        fs.writeFileSync(tilePath, JSON.stringify(tileData));
                    }
                } catch (e) {
                    console.error('Error processing tile:', e);
                }
            }
        }
    });
}

function lonLatToTile(lon: number, lat: number, zoom: number) {
    const x = Math.floor((lon + 180) / 360 * Math.pow(2, zoom));
    const latRad = lat * Math.PI / 180;
    const y = Math.floor((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2 * Math.pow(2, zoom));
    return { x, y };
}

function tileToBbox(x: number, y: number, z: number): [number, number, number, number] {
    const w = tile2long(x, z);
    const e = tile2long(x + 1, z);
    const n = tile2lat(y, z);
    const s = tile2lat(y + 1, z);
    return [w, s, e, n];
}

function tile2long(x: number, z: number) {
    return (x / Math.pow(2, z) * 360 - 180);
}

function tile2lat(y: number, z: number) {
    const n = Math.PI - 2 * Math.PI * y / Math.pow(2, z);
    return (180 / Math.PI * Math.atan(0.5 * (Math.exp(n) - Math.exp(-n))));
}

function ensureDirectoryExistence(filePath: string) {
    const dirname = path.dirname(filePath);
    if (!fs.existsSync(dirname)) {
        fs.mkdirSync(dirname, { recursive: true });
    }
}

const isMain = require.main === module;
if (isMain) {
    const kmlFile = process.argv[2];
    const outDir = process.argv[3] || '../data/tiles';

    if (!kmlFile) {
        console.error("Usage: ts-node src/processor.ts <kml-file> [output-dir]");
        process.exit(1);
    }

    const absoluteKmlPath = path.isAbsolute(kmlFile) ? kmlFile : path.resolve(process.cwd(), kmlFile);
    const absoluteOutDir = path.isAbsolute(outDir) ? outDir : path.resolve(process.cwd(), outDir);

    console.log(`Processing ${absoluteKmlPath}...`);
    if (!fs.existsSync(absoluteKmlPath)) {
        console.error(`File not found: ${absoluteKmlPath}`);
        process.exit(1);
    }

    try {
        const geojson = convertKmlToGeoJson(absoluteKmlPath);
        console.log(`Converted to GeoJSON with ${geojson.features.length} features.`);
        tileGeoJson(geojson, 15, absoluteOutDir);
        console.log("Tiling complete.");
    } catch (error) {
        console.error("Failed to process KML:", error);
        process.exit(1);
    }
}
