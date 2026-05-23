import geoLocationManager from '@ohos.geoLocationManager';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import { wantAgent, WantAgent } from '@kit.AbilityKit';

export interface Breadcrumb {
  lat: number;
  lon: number;
  timestamp: number;
}

export class LocationService {
  private static instance: LocationService;
  private context: common.UIAbilityContext;
  private locationCallback: (location: geoLocationManager.Location) => void = () => {};
  private breadcrumbs: Breadcrumb[] = [];
  private logFilePath: string;

  private constructor(context: common.UIAbilityContext) {
    this.context = context;
    this.logFilePath = `${this.context.filesDir}/breadcrumbs.json`;
  }

  public static getInstance(context: common.UIAbilityContext): LocationService {
    if (!LocationService.instance) {
      LocationService.instance = new LocationService(context);
    }
    return LocationService.instance;
  }

  public async requestPermissions(): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    const permissions: Array<Permissions> = [
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION',
      'ohos.permission.KEEP_BACKGROUND_RUNNING'
    ];

    try {
      const data = await atManager.requestPermissionsFromUser(this.context, permissions);
      let grantStatus: Array<number> = data.authResults;
      return grantStatus.every(status => status === 0);
    } catch (err) {
      console.error('Permission request failed: ' + JSON.stringify(err));
      return false;
    }
  }

  private async getWantAgent(): Promise<WantAgent> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: this.context.abilityInfo.bundleName,
          abilityName: this.context.abilityInfo.name,
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    return await wantAgent.getWantAgent(wantAgentInfo);
  }

  public async startTracking(callback: (location: geoLocationManager.Location) => void) {
    this.locationCallback = callback;
    
    // Start background task with proper WantAgent for HarmonyOS 6.1
    const agent = await this.getWantAgent();
    try {
      await backgroundTaskManager.startBackgroundRunning(this.context, 
        backgroundTaskManager.BackgroundMode.LOCATION, 
        agent
      );
      console.info('Continuous background task started');
    } catch (err) {
      console.error('Failed to start background task: ' + JSON.stringify(err));
    }

    const requestInfo: geoLocationManager.LocationRequest = {
      'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
      'scenario': geoLocationManager.LocationRequestScenario.NAVIGATION,
      'timeInterval': 2,
      'distanceInterval': 0,
      'maxAccuracy': 0
    };

    try {
      geoLocationManager.on('locationChange', requestInfo, (location) => {
        const crumb: Breadcrumb = {
          lat: location.latitude,
          lon: location.longitude,
          timestamp: Date.now()
        };
        this.breadcrumbs.push(crumb);
        this.saveBreadcrumbs();
        this.locationCallback(location);
      });
    } catch (err) {
      console.error('Failed to start tracking: ' + JSON.stringify(err));
    }
  }

  private saveBreadcrumbs() {
    try {
      const file = fs.openSync(this.logFilePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      fs.writeSync(file.fd, JSON.stringify(this.breadcrumbs));
      fs.closeSync(file);
    } catch (err) {
      console.error('Failed to save breadcrumbs: ' + JSON.stringify(err));
    }
  }

  public getBreadcrumbs(): Breadcrumb[] {
    return this.breadcrumbs;
  }

  public async stopTracking() {
    try {
      geoLocationManager.off('locationChange');
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      console.info('Tracking and background task stopped');
    } catch (err) {
      console.error('Failed to stop tracking: ' + JSON.stringify(err));
    }
  }
}
