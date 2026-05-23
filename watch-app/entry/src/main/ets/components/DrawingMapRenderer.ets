import { drawing } from '@kit.ArkGraphics2D';
import { common } from '@kit.AbilityKit';
import { TileService } from '../services/TileService';

@Component
export struct DrawingMapRenderer {
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  @Prop @Watch('onLocationUpdate') currentLat: number;
  @Prop @Watch('onLocationUpdate') currentLon: number;

  @State offsetX: number = 0;
  @State offsetY: number = 0;
  @State scale: number = 1.0;
  
  private zoom: number = 15;
  private tileService?: TileService;
  private tileCache: Map<string, any> = new Map();
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
        this.renderWithDrawing();
      })
      .focusable(true) // Ensure it can receive crown events
      .onDigitalCrown((event: CrownEvent) => {
          // Watch Fit 5 Crown support for zooming
          const zoomSpeed = 0.05;
          if (event.degree > 0) {
              this.scale *= (1 + zoomSpeed);
          } else {
              this.scale *= (1 - zoomSpeed);
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
              this.scale *= event.scale;
              this.renderWithDrawing();
            })
        )
      )
  }

  private renderWithDrawing() {
    if (!this.context) return;
    
    // In HarmonyOS NEXT, we can get the DrawContext from the Canvas
    // and use the high-performance Drawing SDK
    const canvas = this.context.getCanvas();
    if (!canvas) {
      // Fallback to normal canvas if Drawing SDK isn't available
      this.renderNormalCanvas();
      return;
    }

    const width = this.context.width;
    const height = this.context.height;

    // Clear background using Drawing
    const brush = new drawing.Brush();
    brush.setColor({ alpha: 255, red: 0, green: 0, blue: 0 });
    canvas.attachBrush(brush);
    canvas.drawRect({ left: 0, top: 0, right: width, bottom: height });
    canvas.detachBrush();

    // Setup Pen for roads
    const penUntraveled = new drawing.Pen();
    penUntraveled.setColor({ alpha: 255, red: 192, green: 28, blue: 40 }); // #c01c28
    penUntraveled.setStrokeWidth(4 * this.scale);
    penUntraveled.setJoinStyle(drawing.JoinStyle.ROUND);
    penUntraveled.setCapStyle(drawing.CapStyle.ROUND);

    const penTraveled = new drawing.Pen();
    penTraveled.setColor({ alpha: 255, red: 71, green: 173, blue: 95 }); // #47ad5f
    penTraveled.setStrokeWidth(4 * this.scale);
    penTraveled.setJoinStyle(drawing.JoinStyle.ROUND);
    penTraveled.setCapStyle(drawing.CapStyle.ROUND);

    // Draw roads from cached tiles
    this.activeTiles.forEach(tileKey => {
      const tileData = this.tileCache.get(tileKey);
      if (!tileData) return;

      tileData.features.forEach((feature: any) => {
        if (feature.geometry.type === 'LineString') {
          const path = new drawing.Path();
          const coords = feature.geometry.coordinates;
          if (coords.length > 0) {
            path.moveTo(this.lonToX(coords[0][0], width), this.latToY(coords[0][1], height));
            for (let i = 1; i < coords.length; i++) {
              path.lineTo(this.lonToX(coords[i][0], width), this.latToY(coords[i][1], height));
            }
          }

          if (feature.properties.status === 'traveled') {
            canvas.attachPen(penTraveled);
          } else {
            canvas.attachPen(penUntraveled);
          }
          canvas.drawPath(path);
          canvas.detachPen();
        }
      });
    });

    // Draw Breadcrumbs (Recorded Path) using Drawing SDK
    const locationService = LocationService.getInstance(getContext(this) as common.UIAbilityContext);
    const crumbs = locationService.getBreadcrumbs();
    
    if (crumbs.length > 1) {
        const pathCrumb = new drawing.Path();
        pathCrumb.moveTo(this.lonToX(crumbs[0].lon, width), this.latToY(crumbs[0].lat, height));
        for (let i = 1; i < crumbs.length; i++) {
            pathCrumb.lineTo(this.lonToX(crumbs[i].lon, width), this.latToY(crumbs[i].lat, height));
        }
        
        const penCrumb = new drawing.Pen();
        penCrumb.setColor({ alpha: 255, red: 0, green: 122, blue: 255 }); // Blue
        penCrumb.setStrokeWidth(3 * this.scale);
        penCrumb.setJoinStyle(drawing.JoinStyle.ROUND);
        penCrumb.setCapStyle(drawing.CapStyle.ROUND);
        
        canvas.attachPen(penCrumb);
        canvas.drawPath(pathCrumb);
        canvas.detachPen();
    }

    // Draw GPS indicator
    const gpsX = width / 2 + this.offsetX;
    const gpsY = height / 2 + this.offsetY;
    
    const gpsBrush = new drawing.Brush();
    gpsBrush.setColor({ alpha: 255, red: 0, green: 122, blue: 255 });
    canvas.attachBrush(gpsBrush);
    canvas.drawCircle(gpsX, gpsY, 10);
    canvas.detachBrush();
    
    const gpsPen = new drawing.Pen();
    gpsPen.setColor({ alpha: 255, red: 255, green: 255, blue: 255 });
    gpsPen.setStrokeWidth(3);
    canvas.attachPen(gpsPen);
    canvas.drawCircle(gpsX, gpsY, 10);
    canvas.detachPen();
  }

  private renderNormalCanvas() {
      // Original CanvasRenderingContext2D implementation as fallback
  }
}
