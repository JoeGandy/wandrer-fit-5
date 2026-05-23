import UIAbility from '@ohos.app.ability.UIAbility';
import window from '@ohos.window';
import { Want, AbilityConstant } from '@kit.AbilityKit';
import { TileService } from '../services/TileService';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('EntryAbility onCreate');
    // Seed initial data for prototype
    const tileService = TileService.getInstance(this.context);
    tileService.seedSampleData();
  }

  onDestroy(): void {
    console.info('EntryAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('EntryAbility onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('Failed to load the content. Cause: ' + JSON.stringify(err) ?? '');
        return;
      }
      console.info('Succeeded in loading the content. Data: ' + JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    console.info('EntryAbility onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('EntryAbility onForeground');
  }

  onBackground(): void {
    console.info('EntryAbility onBackground');
  }
}
