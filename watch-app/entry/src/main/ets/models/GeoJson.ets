/**
 * Subset of GeoJSON types required for Wandrer tile rendering.
 * Defined locally to avoid external dependency issues in HarmonyOS/ohpm.
 * Updated for ArkTS strict typing compliance.
 */

export type Position = number[];

export interface Geometry {
  type: string;
}

export interface LineString extends Geometry {
  type: 'LineString';
  coordinates: Position[];
}

export interface Feature<G extends Geometry, P> {
  type: 'Feature';
  geometry: G;
  properties: P;
  id?: string | number;
}

export interface FeatureCollection<G extends Geometry, P> {
  type: 'FeatureCollection';
  features: Array<Feature<G, P>>;
}
