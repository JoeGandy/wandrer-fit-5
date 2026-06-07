import { TileService, TileFeatureProperties } from '../services/TileService';
import { LocationService } from '../services/LocationService';
import { FeatureCollection, LineString, Feature, Position } from '../models/GeoJson';
import common from '@ohos.app.ability.common';

@Component
export struct SyncPage {
  @State syncStatus: string = 'Ready to Sync';
  @State syncProgress: number = 0;
  @State breadcrumbCount: number = 0;
  
  private tileService?: TileService;
  private locationService?: LocationService;

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.tileService = TileService.getInstance(context);
    this.locationService = LocationService.getInstance(context);
    this.updateStats();
  }

  updateStats() {
    if (this.locationService) {
      this.breadcrumbCount = this.locationService.getBreadcrumbs().length;
    }
  }

  simulateSync() {
    if (!this.tileService) return;
    
    this.syncStatus = 'Syncing...';
    this.syncProgress = 0;
    
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

    const interval = setInterval(() => {
      this.syncProgress += 10;
      if (this.syncProgress >= 100) {
        clearInterval(interval);
        
        // Save tiles to sandbox for specific Pinxton coordinates
        // Zoom 15, x=16265, y=10658 (Pinxton area)
        this.tileService?.saveTile(15, 16265, 10658, pinxtonTile);
        this.tileService?.saveTile(15, 16259, 10658, pinxtonTile); // Also save to the one used in spike
        
        this.syncStatus = 'Sync Complete';
        this.syncProgress = 100;
      }
    }, 200);
  }

  clearData() {
    this.tileService?.clearTiles();
    this.syncStatus = 'Data Cleared';
    this.syncProgress = 0;
  }

  build() {
    Column() {
      Text('Sync Center')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ bottom: 20 })

      Text(this.syncStatus)
        .fontSize(16)
        .fontColor(this.syncStatus === 'Sync Complete' ? Color.Green : Color.Gray)
        .margin({ bottom: 10 })

      Progress({ value: this.syncProgress, total: 100, type: ProgressType.Linear })
        .width('80%')
        .margin({ bottom: 20 })

      Button('Start Sync')
        .width('80%')
        .backgroundColor('#47ad5f')
        .margin({ bottom: 10 })
        .onClick(() => this.simulateSync())

      Button('Clear Cache')
        .width('80%')
        .backgroundColor('#c01c28')
        .margin({ bottom: 10 })
        .onClick(() => this.clearData())

      Button(`Export Path (${this.breadcrumbCount})`)
        .width('80%')
        .backgroundColor('#007aff')
        .onClick(() => {
            if (this.locationService) {
                this.breadcrumbCount = this.locationService.getBreadcrumbs().length;
            }
        })
        
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(Color.Black)
    .justifyContent(FlexAlign.Center)
  }
}
