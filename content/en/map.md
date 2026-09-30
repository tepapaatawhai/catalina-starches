---
date: '2025-01-30T03:36:57-08:00'
draft: false
tabTitle: 'Search: Catalina Heritage Register'
title: 'Catalina Heritage Register'
text: 'Map page'
type: '_default'
url: /
layout: 'map-search'
includeSearch: true
center: "[172.5, -41.5]"
zoom: 5
mobileZoom: 3
map_config:
  defaultBasemap: "map"
  basemaps:
    - id: "map"
      label: "Map"
      config:
        type: "style"
        url: "https://tiles.openfreemap.org/styles/bright"
        attribution: ""
    - id: "osm"
      label: "Open Street Map"
      config:
        type: "raster"
        tiles: "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution: ""
    - id: "satellite"
      label: "Satellite"
      config:
        type: "raster"
        tiles: "https://basemaps.linz.govt.nz/v1/tiles/aerial/3857/{z}/{x}/{y}.webp?api={linz_api_key}"
        attribution: "&copy; <a href='https://www.linz.govt.nz' target='_blank'>LINZ</a> CC-BY 4.0"

---