import { DrawingMapRenderer } from '../components/DrawingMapRenderer';
import { SyncPage } from '../components/SyncPage';
import { SettingsPage } from '../components/SettingsPage';
import { LocationService } from '../services/LocationService';
import { LiveViewService } from '../services/LiveViewService';
import common from '@ohos.app.ability.common';
import geoLocationManager from '@ohos.geoLocationManager';

@Entry
@Component
struct Index {
  @State message: string = 'Watch Wandrer MVP';
  @State currentLatitude: number = 53.0940; // Default to Pinxton
  @State currentLongitude: number = -1.3438;
  @State currentIndex: number = 0;
  @State isRecording: boolean = false;
  private locationService?: LocationService;
  private liveViewService?: LiveViewService;
  private controller: TabsController = new TabsController();

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.locationService = LocationService.getInstance(context);
    this.liveViewService = LiveViewService.getInstance(context);
    this.initLocation();
  }

  async initLocation() {
    if (this.locationService) {
      const granted = await this.locationService.requestPermissions();
      if (!granted) {
        this.message = 'Location Permission Denied';
      }
    }
  }

  toggleRecording() {
    if (!this.locationService || !this.liveViewService) return;

    if (this.isRecording) {
      this.locationService.stopTracking();
      this.liveViewService.stopLiveView();
      this.isRecording = false;
      this.message = 'Recording Stopped';
    } else {
      this.liveViewService.startExplorationLiveView(0, 0);
      this.locationService.startTracking((location: geoLocationManager.Location) => {
        this.currentLatitude = location.latitude;
        this.currentLongitude = location.longitude;
        this.message = `Lat: ${location.latitude.toFixed(4)}, Lon: ${location.longitude.toFixed(4)}`;
        
        // Update LiveView periodically (simulated stats for prototype)
        const distance = this.locationService?.getBreadcrumbs().length || 0;
        this.liveViewService?.updateStats(distance * 0.01, Math.floor(distance / 10));
      });
      this.isRecording = true;
      this.message = 'Recording...';
    }
  }

  aboutToDisappear() {
    this.locationService?.stopTracking();
  }

  @Builder TabBuilder(index: number, name: string) {
    Column() {
      Text(name)
        .fontColor(this.currentIndex === index ? '#007aff' : '#86868b')
        .fontSize(10)
        .fontWeight(this.currentIndex === index ? 500 : 400)
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
        this.currentIndex = index;
        this.controller.changeIndex(index);
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
      TabContent() {
        Stack() {
          DrawingMapRenderer({
            currentLat: this.currentLatitude,
            currentLon: this.currentLongitude
          })
            .width('100%')
            .height('100%')
          
          Column() {
            Row() {
               if (this.isRecording) {
                 Circle({ width: 8, height: 8 })
                   .fill(Color.Red)
                   .margin({ right: 4 })
               }
               Text(this.message)
                 .fontSize(10)
                 .fontColor(Color.White)
            }
            .backgroundColor('#80000000')
            .padding(4)
            .borderRadius(4)
            .margin({ top: 10 })

            Blank()

            Button(this.isRecording ? 'Stop' : 'Record')
              .fontSize(12)
              .backgroundColor(this.isRecording ? '#c01c28' : '#47ad5f')
              .width(80)
              .height(30)
              .margin({ bottom: 60 })
              .onClick(() => this.toggleRecording())
          }
          .width('100%')
          .height('100%')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.SpaceBetween)
        }
      }.tabBar(this.TabBuilder(0, 'Map'))

      TabContent() {
        SyncPage()
      }.tabBar(this.TabBuilder(1, 'Sync'))

      TabContent() {
        SettingsPage()
      }.tabBar(this.TabBuilder(2, 'Set'))
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.Black)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}
