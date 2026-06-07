import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import { FeatureCollection, LineString, Position, Feature } from '../models/GeoJson';

export interface TileFeatureProperties {
  status: 'untraveled' | 'traveled' | 'unpaved' | 'achievement' | 'unknown';
}

export interface TileCoordinates {
  x: number;
  y: number;
}

export class TileService {
  private static instance: TileService;
  private context: common.UIAbilityContext;
  private tilesDir: string;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    // Tiles are stored in the application's files directory under 'tiles'
    this.tilesDir = `${this.context.filesDir}/tiles`;
    this.ensureTilesDir();
  }

  public static getInstance(context: common.UIAbilityContext): TileService {
    if (!TileService.instance) {
      TileService.instance = new TileService(context);
    }
    return TileService.instance;
  }

  private ensureTilesDir() {
    try {
      if (!fs.accessSync(this.tilesDir)) {
        fs.mkdirSync(this.tilesDir);
        console.info('Created tiles directory: ' + this.tilesDir);
      }
    } catch (err) {
      console.error('Failed to access/create tiles directory: ' + JSON.stringify(err));
    }
  }

  /**
   * Loads a tile from the local filesystem
   * @param zoom 
   * @param x 
   * @param y 
   */
  public async loadTile(zoom: number, x: number, y: number): Promise<FeatureCollection<LineString, TileFeatureProperties> | null> {
    const tilePath = `${this.tilesDir}/${zoom}/${x}/${y}.json`;
    
    try {
      if (!fs.accessSync(tilePath)) {
        return null;
      }

      const content = fs.readTextSync(tilePath);
      return JSON.parse(content) as FeatureCollection<LineString, TileFeatureProperties>;
    } catch (err) {
      console.error(`Failed to load tile ${zoom}/${x}/${y}: ` + JSON.stringify(err));
      return null;
    }
  }

  /**
   * Helper to convert lon/lat to tile coordinates
   */
  public lonLatToTile(lon: number, lat: number, zoom: number): TileCoordinates {
    const x = Math.floor((lon + 180) / 360 * Math.pow(2, zoom));
    const latRad = lat * Math.PI / 180;
    const y = Math.floor((1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI) / 2 * Math.pow(2, zoom));
    return { x: x, y: y } as TileCoordinates;
  }

  /**
   * Save a tile (used during sync)
   */
  public saveTile(zoom: number, x: number, y: number, data: string): void {
    const zDir = `${this.tilesDir}/${zoom}`;
    const xDir = `${zDir}/${x}`;
    const tilePath = `${xDir}/${y}.json`;

    try {
      if (!fs.accessSync(zDir)) fs.mkdirSync(zDir);
      if (!fs.accessSync(xDir)) fs.mkdirSync(xDir);
      
      const file = fs.openSync(tilePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, data);
      fs.closeSync(file);
      console.info(`Saved tile: ${tilePath}`);
    } catch (err) {
      console.error(`Failed to save tile ${zoom}/${x}/${y}: ` + JSON.stringify(err));
    }
  }

  public seedSampleData(): void {
    const f1: Feature<LineString, TileFeatureProperties> = {
      type: 'Feature',
      properties: { status: 'traveled' } as TileFeatureProperties,
      geometry: {
        type: 'LineString',
        coordinates: [[-1.363163, 53.100627], [-1.362305, 53.100576], [-1.360835, 53.100505], [-1.359397, 53.100402], [-1.3562, 53.100221]] as Position[]
      } as LineString
    } as Feature<LineString, TileFeatureProperties>;

    const f2: Feature<LineString, TileFeatureProperties> = {
      type: 'Feature',
      properties: { status: 'untraveled' } as TileFeatureProperties,
      geometry: {
        type: 'LineString',
        coordinates: [[-1.343869, 53.094024], [-1.343888, 53.094208], [-1.343861, 53.094477]] as Position[]
      } as LineString
    } as Feature<LineString, TileFeatureProperties>;

    const fc: FeatureCollection<LineString, TileFeatureProperties> = {
      type: 'FeatureCollection',
      features: [f1, f2]
    } as FeatureCollection<LineString, TileFeatureProperties>;

    const pinxtonTile = JSON.stringify(fc);

    // Seed a few tiles around Pinxton
    this.saveTile(15, 16265, 10658, pinxtonTile);
    this.saveTile(15, 16259, 10658, pinxtonTile);
    console.info('Sample data seeded.');
  }

  public clearTiles() {
    try {
      fs.rmdirSync(this.tilesDir);
      this.ensureTilesDir();
    } catch (err) {
      console.error('Failed to clear tiles: ' + JSON.stringify(err));
    }
  }
}
