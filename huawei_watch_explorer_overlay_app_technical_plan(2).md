# Huawei Watch Offline Explorer Overlay App — Technical Development Plan

## Overview

This project aims to build an offline-first exploration app for Huawei HarmonyOS watches (initially targeting the HUAWEI WATCH FIT series) that displays:

- Wandrer unexplored roads
- Squadrats overlays
- GPS position
- Offline map data
- Exploration progress

The application must:

- work fully offline on the watch
- function independently from the phone while outdoors
- sync data when paired with the phone later
- efficiently render large spatial datasets on constrained watch hardware

The phone acts primarily as:

- sync engine
- preprocessing engine
- tile generator
- data source manager

The watch acts primarily as:

- renderer
- GPS tracker
- offline explorer client

---

# High-Level Architecture

```text
                 ┌────────────────────┐
                 │   Wandrer Export   │
                 │  GPX / KML / APIs  │
                 └─────────┬──────────┘
                           │
                 ┌─────────▼──────────┐
                 │  Phone Processing  │
                 │                    │
                 │ - Parse overlays   │
                 │ - Simplify data    │
                 │ - Generate tiles   │
                 │ - Compress assets  │
                 │ - Sync management  │
                 └─────────┬──────────┘
                           │
                 Sync via Bluetooth
                           │
                 ┌─────────▼──────────┐
                 │   Watch Runtime    │
                 │                    │
                 │ - GPS tracking     │
                 │ - Tile loading     │
                 │ - Overlay render   │
                 │ - Interaction      │
                 │ - Offline usage    │
                 └────────────────────┘
```

---

# Primary Goals

## Core Features

### MVP

- Offline watch-only operation
- Current GPS position
- Render nearby unexplored roads
- Render squadrat overlays
- Pan + zoom map
- Local tile storage
- Record travelled paths
- Sync completion updates later

### Future Features

- Heatmaps
- Nearby unexplored-road alerts
- Route suggestions
- Completion percentages
- Community overlays
- Offline routing
- Multiple map styles
- Cloud sync
- Strava integration

---

# Technical Constraints

## Watch Hardware Constraints

Assume:

- low RAM
- limited GPU
- limited CPU
- limited storage
- limited battery
- thermal throttling

Therefore:

- avoid large in-memory datasets
- avoid expensive geometry operations on-watch
- avoid XML parsing on-watch
- avoid full GIS stack on-watch
- aggressively cull and simplify geometry

---

# Technology Stack

# Watch Application

## Platform

- HarmonyOS
- ArkTS
- DevEco Studio

## Languages

- TypeScript / ArkTS

## Responsibilities

- render overlays
- GPS acquisition
- local tile loading
- pan/zoom interactions
- offline storage
- record breadcrumbs

---

# Phone Application

## Recommended Stack

- React Native OR native Android initially
- TypeScript
- Node.js processing runtime

## Responsibilities

- import KML/GPX
- sync Wandrer exports
- process geometry
- generate watch tiles
- compress assets
- sync travelled-road updates

---

# Data Pipeline

# Important Design Principle

DO NOT send raw KML to the watch.

Everything must be transformed into optimized spatial tiles.

---

# Input Sources

## Supported Inputs

### Phase 1

- Wandrer KML exports
- Wandrer GPX exports
- Squadrats GeoJSON

### Future

- Strava exports
- OpenStreetMap extracts
- custom overlays
- route imports

---

# Internal Standard Format

All imported formats should normalize into GeoJSON-like internal structures.

Example:

```json
{
  "type": "Feature",
  "geometry": {
    "type": "LineString",
    "coordinates": [[lon, lat], [lon, lat]]
  },
  "properties": {
    "layer": "wandrer",
    "status": "untravelled"
  }
}
```

---

# Tile-Based Spatial Architecture

## Why Tiles Matter

A watch cannot efficiently render:

- entire counties
- large KMLs
- all roads simultaneously

Instead:

- split data spatially
- load only nearby geometry
- unload distant geometry

---

# Tile System

## Recommended Scheme

Use slippy-map style XYZ tiles.

Example:

```text
z/x/y
14/8231/5461
```

---

# Tile Zoom Levels

## Suggested Levels

| Zoom | Purpose |
|---|---|
| 10 | large regional overview |
| 12 | city overview |
| 14 | cycling / walking overview |
| 16 | detailed street view |

Avoid excessive zoom levels initially.

---

# Tile Payload Format

## Suggested Compact Binary Structure

Long-term:

```text
Custom binary format
```

Initially:

```json
{
  "roads": [...],
  "polygons": [...],
  "markers": [...]
}
```

compressed with:

- gzip
- brotli

---

# Geometry Simplification

## Required

Raw GPS/vector data will be too heavy.

Use:

- Douglas-Peucker simplification
- Visvalingam simplification

Libraries:

- mapshaper
- simplify-js
- turf

---

# Spatial Indexing

## Required

The watch must rapidly answer:

```text
What geometry is near me?
```

Recommended:

- tile-based indexing
- R-tree indexing
- quadtrees

Libraries:

- rbush

---

# Rendering Engine

# Design Goal

The renderer should behave more like:

```text
minimal GIS viewer
```

than:

```text
full map engine
```

---

# Initial Rendering Strategy

## Phase 1

Render only:

- current GPS position
- unexplored roads
- squadrat polygons

No basemap initially.

This dramatically reduces complexity.

---

# Coordinate System

## Internal Standard

Use:

```text
WGS84
```

Internally.

---

# Projection

Convert to:

```text
Web Mercator
```

for rendering.

---

# Coordinate Transform Pipeline

```text
lat/lon
→ Web Mercator
→ viewport transform
→ screen coordinates
```

---

# Viewport Culling

## Required

Never render off-screen geometry.

Pipeline:

```text
Load nearby tiles
→ Clip geometry to viewport
→ Render visible segments only
```

---

# Overlay Layers

# Supported Layer Types

## Lines

Examples:

- unexplored roads
- routes
- trails

---

## Polygons

Examples:

- squadrats
- completion regions
- heatmap areas

---

## Markers

Examples:

- POIs
- goals
- current location

---

# Overlay Abstraction

Use generalized feature rendering.

Example:

```json
{
  "type": "polygon",
  "layer": "squadrats",
  "coordinates": [...],
  "style": {
    "fill": true
  }
}
```

---

# Map Interaction

# MVP Interactions

## Required

- drag/pan
- zoom in/out
- center on GPS
- toggle layers

---

# GPS Tracking

# Requirements

The watch should:

- continuously track position during activity
- cache breadcrumbs locally
- work offline

---

# Breadcrumb Recording

## Example

```json
[
  [lat, lon, timestamp],
  [lat, lon, timestamp]
]
```

---

# Travelled-Road Matching

# Important

Do NOT do road matching on-watch.

Perform on phone during sync.

Pipeline:

```text
Watch breadcrumbs
→ Phone sync
→ Snap to road network
→ Update completion state
→ Regenerate affected tiles
→ Sync back to watch
```

---

# Basemap Strategy

# Recommended Approach

## Phase 1

No basemap.

Just overlays.

---

## Phase 2

Add raster map tiles.

Recommended:

- OpenStreetMap
- grayscale tiles
- low-detail style

---

# Offline Tile Storage

## Suggested Format

MBTiles OR local tile folders.

---

# Tile Generation Tools

## Recommended

- Planetiler
- TileServer GL
- OpenMapTiles

---

# Squadrats Support

# Data Characteristics

Squadrats are lightweight compared to road overlays.

Mostly:

- polygons
- grid squares
- visited state

This should render efficiently.

---

# Squadrats Layer Example

```json
{
  "type": "polygon",
  "layer": "squadrats",
  "id": "SD91",
  "visited": false,
  "coordinates": [...]
}
```

---

# Layer Styling

## Suggested Defaults

| Layer | Style |
|---|---|
| unexplored roads | bright red |
| travelled roads | grey |
| current square | highlighted fill |
| completed squares | muted fill |
| GPS position | blue/white dot |

---

# Sync System

# Sync Philosophy

The watch should always function independently.

Phone sync is:

- opportunistic
- asynchronous
- non-blocking

---

# Sync Responsibilities

## Phone → Watch

- new overlay tiles
- map updates
- style updates
- metadata

---

## Watch → Phone

- breadcrumbs
- activity sessions
- completion changes
- diagnostics

---

# Compression Strategy

## Required

Minimize Bluetooth payload sizes.

Use:

- gzip
- brotli
- delta updates

---

# Storage Management

# Required Features

- region downloads
- cache eviction
- tile expiration
- low-storage handling

---

# Suggested Initial Limits

| Resource | Suggested Limit |
|---|---|
| offline region | 50–200 MB |
| active tiles in memory | 20–50 |
| breadcrumb cache | several days |

---

# Performance Optimization

# Critical Optimizations

## Geometry Simplification

Required.

---

## Tile Culling

Required.

---

## Batched Rendering

Required.

Avoid drawing each segment independently.

---

## Zoom-Based Filtering

Examples:

- hide tiny roads at low zoom
- reduce geometry detail when zoomed out

---

# Battery Optimization

# GPS Strategy

Do not run maximum-frequency GPS continuously.

Suggested:

- adaptive update intervals
- movement-based sampling
- low-power idle mode

---

# UI Design Principles

# Important

Watch screens are tiny.

Prioritize:

- glanceability
- minimal clutter
- high contrast
- large tap targets

---

# Recommended Watch Screens

## Main Map

Shows:

- current position
- nearby unexplored roads
- squadrats overlay

---

## Nearby Targets

Shows:

- nearest unexplored roads
- nearest incomplete squares

---

## Activity Summary

Shows:

- roads completed
- squares completed
- distance

---

# Development Phases

# Phase 0 — Research

## Goals

- verify HarmonyOS capabilities
- verify graphics APIs
- verify local storage APIs
- verify GPS access
- verify Bluetooth sync

Deliverables:

- minimal watch app
- GPS test
- canvas rendering test

---

# Phase 1 — Desktop Prototype

## Goals

- parse Wandrer export
- render overlays in browser
- implement tile generation
- implement simplification

Deliverables:

- browser renderer
- tile generator
- performance benchmarks

---

# Phase 2 — Watch Renderer Prototype

## Goals

- render local tiles on watch
- implement pan/zoom
- render GPS position

Deliverables:

- smooth offline rendering
- viewport culling

---

# Phase 3 — Offline Sync

## Goals

- phone-to-watch sync
- tile transfer
- breadcrumb upload

Deliverables:

- reliable sync system
- offline persistence

---

# Phase 4 — Basemap Integration

## Goals

- add raster basemap
- improve visual context

Deliverables:

- offline map regions
- tile caching

---

# Phase 5 — Exploration Features

## Goals

- completion metrics
- nearby targets
- overlay management
- route suggestions

---

# Suggested Libraries

# Geospatial

| Library | Purpose |
|---|---|
| turf | geometry ops |
| geojson-vt | vector tiling |
| rbush | spatial indexing |
| simplify-js | geometry simplification |
| mapshaper | preprocessing |

---

# Mapping

| Tool | Purpose |
|---|---|
| Planetiler | tile generation |
| OpenMapTiles | basemap generation |
| TileServer GL | local tile serving |

---

# Key Risks

# Highest Risks

| Risk | Severity |
|---|---|
| watch rendering performance | critical |
| battery drain | high |
| HarmonyOS limitations | high |
| memory constraints | high |
| Bluetooth sync throughput | medium |
| large overlay datasets | medium |

---

# Success Criteria

# MVP Success

The project succeeds if the watch can:

- operate fully offline
- show current GPS position
- render nearby unexplored roads smoothly
- render squadrats overlays smoothly
- survive multi-hour outdoor activities
- sync updates reliably later

---

# Long-Term Vision

Potentially evolve into:

- offline exploration platform
- Garmin Explore alternative
- lightweight GIS watch client
- Wandrer companion ecosystem
- exploration gamification platform

focused on:

- walkers
- cyclists
- runners
- explorers
- map enthusiasts
- squadrats users

