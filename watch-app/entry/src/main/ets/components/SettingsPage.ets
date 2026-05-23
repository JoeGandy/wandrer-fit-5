import { TileService } from '../services/TileService';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';

@Component
export struct SettingsPage {
  @State cacheSize: string = 'Calculating...';
  private tileService?: TileService;

  aboutToAppear() {
    const context = getContext(this) as common.UIAbilityContext;
    this.tileService = TileService.getInstance(context);
    this.updateStats();
  }

  updateStats() {
    // Simulated cache size calculation for prototype
    setTimeout(() => {
      this.cacheSize = '1.2 MB';
    }, 500);
  }

  build() {
    Column() {
      Text('Settings')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .margin({ bottom: 20 })

      List() {
        ListItem() {
          Row() {
            Text('Zoom Level')
              .fontColor(Color.White)
            Blank()
            Text('15')
              .fontColor(Color.Gray)
          }
          .width('100%')
          .padding(10)
        }

        ListItem() {
          Row() {
            Text('Cache Size')
              .fontColor(Color.White)
            Blank()
            Text(this.cacheSize)
              .fontColor(Color.Gray)
          }
          .width('100%')
          .padding(10)
        }

        ListItem() {
          Button('Reset All Data')
            .width('100%')
            .backgroundColor('#c01c28')
            .onClick(() => {
              this.tileService?.clearTiles();
              // Also clear breadcrumbs
              const context = getContext(this) as common.UIAbilityContext;
              try {
                  const logPath = `${context.filesDir}/breadcrumbs.json`;
                  if (fs.accessSync(logPath)) {
                      fs.unlinkSync(logPath);
                  }
              } catch (e) {
                  console.error('Failed to clear breadcrumbs: ' + JSON.stringify(e));
              }
              this.updateStats();
            })
            .margin({ top: 20 })
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .padding(20)
    .backgroundColor(Color.Black)
  }
}
