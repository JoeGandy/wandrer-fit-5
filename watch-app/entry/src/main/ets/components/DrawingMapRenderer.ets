import { common } from '@kit.AbilityKit';
import { TileService, TileFeatureProperties } from '../services/TileService';
import { FeatureCollection, LineString, Feature } from '../models/GeoJson';
import { LocationService } from '../services/LocationService';

@Component
export struct DrawingMapRenderer {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  @Prop @Watch('onLocationUpdate') currentLat: number;
  @Prop @Watch('onLocationUpdate') currentLon: number;

  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State zoomScale: number = 1.0;
  
  private zoom: number = 15;
  private tileService?: TileService;
  private tileCache: Map<string, FeatureCollection<LineString, TileFeatureProperties>> = new Map();
  private activeTiles: string[] = [];

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.tileService = TileService.getInstance(context);
    this.loadNearbyTiles();
  }

  onLocationUpdate() {
    this.loadNearbyTiles();
    this.renderWithDrawing();
  }

  private async loadNearbyTiles() {
    if (!this.tileService) return;
    const centerTile = this.tileService.lonLatToTile(this.currentLon, this.currentLat, this.zoom);
    const newActiveTiles: string[] = [];

    for (let dx = -1; dx <= 1; dx++) {
      for (let dy = -1; dy <= 1; dy++) {
        const tx = centerTile.x + dx;
        const ty = centerTile.y + dy;
        const tileKey = `${this.zoom}/${tx}/${ty}`;
        newActiveTiles.push(tileKey);
        if (!this.tileCache.has(tileKey)) {
          const data = await this.tileService.loadTile(this.zoom, tx, ty);
          if (data) {
            this.tileCache.set(tileKey, data);
            this.renderWithDrawing();
          }
        }
      }
    }
    this.activeTiles = newActiveTiles;
  }

  private lonToX(lon: number, width: number): number {
    return (lon - this.currentLon) * width * 500 * this.zoomScale + width / 2 + this.offsetX;
  }

  private latToY(lat: number, height: number): number {
    return height / 2 - (lat - this.currentLat) * height * 500 * this.zoomScale + this.offsetY;
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.renderWithDrawing();
      })
      .focusable(true) // Ensure it can receive crown events
      .onDigitalCrown((event: CrownEvent) => {
          // Watch Fit 5 Crown support for zooming
          const zoomSpeed = 0.05;
          if (event.degree > 0) {
              this.zoomScale *= (1 + zoomSpeed);
          } else {
              this.zoomScale *= (1 - zoomSpeed);
          }
          this.renderWithDrawing();
      })
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          PanGesture({ fingers: 1 })
            .onActionUpdate((event: GestureEvent) => {
              this.offsetX += event.offsetX;
              this.offsetY += event.offsetY;
              this.renderWithDrawing();
            }),
          PinchGesture({ fingers: 2 })
            .onActionUpdate((event: GestureEvent) => {
              this.zoomScale *= event.scale;
              this.renderWithDrawing();
            })
        )
      )
  }

  private renderWithDrawing() {
    if (!this.context) return;
    
    const width = this.context.width;
    const height = this.context.height;

    // Clear background
    this.context.fillStyle = '#000000';
    this.context.fillRect(0, 0, width, height);

    // Draw roads from cached tiles
    this.activeTiles.forEach(tileKey => {
      const tileData = this.tileCache.get(tileKey);
      if (!tileData) return;

      tileData.features.forEach((feature: Feature<LineString, TileFeatureProperties>) => {
        if (feature.geometry.type === 'LineString') {
          this.context.beginPath();
          this.context.lineWidth = 4 * this.zoomScale;
          this.context.lineCap = 'round';
          this.context.lineJoin = 'round';
          
          const coords = feature.geometry.coordinates;
          if (coords.length > 0) {
            this.context.moveTo(this.lonToX(coords[0][0], width), this.latToY(coords[0][1], height));
            for (let i = 1; i < coords.length; i++) {
              this.context.lineTo(this.lonToX(coords[i][0], width), this.latToY(coords[i][1], height));
            }
          }

          if (feature.properties.status === 'traveled') {
            this.context.strokeStyle = '#47ad5f'; 
          } else {
            this.context.strokeStyle = '#c01c28'; 
          }
          this.context.stroke();
        }
      });
    });

    // Draw Breadcrumbs (Recorded Path)
    const context = getContext(this) as common.UIAbilityContext;
    const locationService = LocationService.getInstance(context);
    const crumbs = locationService.getBreadcrumbs();
    
    if (crumbs.length > 1) {
        this.context.beginPath();
        this.context.lineWidth = 3 * this.zoomScale;
        this.context.strokeStyle = '#007aff';
        this.context.lineCap = 'round';
        this.context.lineJoin = 'round';
        
        this.context.moveTo(this.lonToX(crumbs[0].lon, width), this.latToY(crumbs[0].lat, height));
        for (let i = 1; i < crumbs.length; i++) {
            this.context.lineTo(this.lonToX(crumbs[i].lon, width), this.latToY(crumbs[i].lat, height));
        }
        this.context.stroke();
    }

    // Draw GPS indicator
    const gpsX = width / 2 + this.offsetX;
    const gpsY = height / 2 + this.offsetY;
    
    this.context.beginPath();
    this.context.arc(gpsX, gpsY, 10, 0, Math.PI * 2);
    this.context.fillStyle = '#007aff';
    this.context.fill();
    this.context.strokeStyle = '#ffffff';
    this.context.lineWidth = 3;
    this.context.stroke();
  }

  private renderNormalCanvas() {
      // Original CanvasRenderingContext2D implementation as fallback
  }
}
