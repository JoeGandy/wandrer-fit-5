import { TileService, TileFeatureProperties } from '../services/TileService';
import { FeatureCollection, LineString } from 'geojson';
import common from '@ohos.app.ability.common';

@Component
export struct MapRenderer {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  @Prop @Watch('onLocationUpdate') currentLat: number;
  @Prop @Watch('onLocationUpdate') currentLon: number;

  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State scale: number = 1.0;
  
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
    this.renderMap();
  }

  private async loadNearbyTiles() {
    if (!this.tileService) return;

    const centerTile = this.tileService.lonLatToTile(this.currentLon, this.currentLat, this.zoom);
    const newActiveTiles: string[] = [];

    // Load 3x3 grid around current tile
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
            this.renderMap(); 
          }
        }
      }
    }
    this.activeTiles = newActiveTiles;
  }

  private lonToX(lon: number, width: number): number {
    return (lon - this.currentLon) * width * 500 * this.scale + width / 2 + this.offsetX;
  }

  private latToY(lat: number, height: number): number {
    return height / 2 - (lat - this.currentLat) * height * 500 * this.scale + this.offsetY;
  }

  build() {
    Canvas(this.context)
      .width('100%')
      .height('100%')
      .onReady(() => {
        this.renderMap();
      })
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          PanGesture({ fingers: 1 })
            .onActionUpdate((event: GestureEvent) => {
              this.offsetX += event.offsetX;
              this.offsetY += event.offsetY;
              this.renderMap();
            }),
          PinchGesture({ fingers: 2 })
            .onActionUpdate((event: GestureEvent) => {
              this.scale *= event.scale;
              this.renderMap();
            })
        )
      )
  }

  private renderMap() {
    if (!this.context) return;
    
    const width = this.context.width;
    const height = this.context.height;

    // Clear background
    this.context.fillStyle = '#000000';
    this.context.fillRect(0, 0, width, height);

    // Draw Grid (Optional for context)
    this.context.strokeStyle = '#222222';
    this.context.lineWidth = 1;
    const gridStep = 0.005;
    for (let i = -5; i <= 5; i++) {
        const x = this.lonToX(this.currentLon + i * gridStep, width);
        this.context.beginPath();
        this.context.moveTo(x, 0);
        this.context.lineTo(x, height);
        this.context.stroke();

        const y = this.latToY(this.currentLat + i * gridStep, height);
        this.context.beginPath();
        this.context.moveTo(0, y);
        this.context.lineTo(width, y);
        this.context.stroke();
    }

    // Draw roads from cached tiles
    this.activeTiles.forEach(tileKey => {
      const tileData = this.tileCache.get(tileKey);
      if (!tileData) return;

      tileData.features.forEach((feature) => {
        if (feature.geometry.type === 'LineString') {
          this.context.beginPath();
          this.context.lineWidth = 4 * this.scale;
          this.context.lineCap = 'round';
          this.context.lineJoin = 'round';
          
          const coords = feature.geometry.coordinates;
          if (coords.length > 0) {
            const startX = this.lonToX(coords[0][0], width);
            const startY = this.latToY(coords[0][1], height);
            this.context.moveTo(startX, startY);

            for (let i = 1; i < coords.length; i++) {
              const x = this.lonToX(coords[i][0], width);
              const y = this.latToY(coords[i][1], height);
              this.context.lineTo(x, y);
            }
          }

          if (feature.properties.status === 'traveled') {
            this.context.strokeStyle = '#47ad5f'; 
          } else if (feature.properties.status === 'untraveled') {
            this.context.strokeStyle = '#c01c28'; 
          } else {
            this.context.strokeStyle = '#666666';
          }
          this.context.stroke();
        }
      });
    });

    // Draw Breadcrumbs (Recorded Path)
    if (this.tileService) {
        const context = getContext(this) as common.UIAbilityContext;
        const locationService = LocationService.getInstance(context);
        const crumbs = locationService.getBreadcrumbs();
        
        if (crumbs.length > 1) {
            this.context.beginPath();
            this.context.lineWidth = 3 * this.scale;
            this.context.strokeStyle = '#007aff'; // Active path blue
            this.context.lineCap = 'round';
            this.context.lineJoin = 'round';
            
            const startX = this.lonToX(crumbs[0].lon, width);
            const startY = this.latToY(crumbs[0].lat, height);
            this.context.moveTo(startX, startY);

            for (let i = 1; i < crumbs.length; i++) {
                const x = this.lonToX(crumbs[i].lon, width);
                const y = this.latToY(crumbs[i].lat, height);
                this.context.lineTo(x, y);
            }
            this.context.stroke();
        }
    }

    // Draw GPS indicator
    const gpsX = width / 2 + this.offsetX;
    const gpsY = height / 2 + this.offsetY;
    this.context.beginPath();
    this.context.arc(gpsX, gpsY, 10, 0, Math.PI * 2);
    this.context.fillStyle = '#ffffff'; // White outer circle for contrast
    this.context.fill();
    this.context.beginPath();
    this.context.arc(gpsX, gpsY, 7, 0, Math.PI * 2);
    this.context.fillStyle = '#007aff';
    this.context.fill();
    this.context.stroke();
  }
}
