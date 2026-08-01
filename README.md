# YamaD status

```cron
* * * * * path/to/myroom_plot.sh
0 * * * * path/to/mass_plot.sh
0 * * * * path/to/vtr_plot.sh
```

## VTR design

```json
{
  "_id": "_design/queries",
  "views": {
    "by_ts": {
      "map": "doc => emit(doc.ts, doc.trip / doc.fuel)"
    }
  }
}
```
