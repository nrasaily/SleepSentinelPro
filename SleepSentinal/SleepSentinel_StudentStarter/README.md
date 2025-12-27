# SleepSentinel — Student Starter (Views Challenge)

This starter gives you a working data layer and a TODO UI layer.

## You implement (in `Views.swift`)
- **OnboardingView**: explainer + "Request Health Access" + optional "Load Demo Data".
- **MainView**: TabView with **Trends**, **Timeline**, **Settings** tabs.
- **TrendsView**: show nights (NEWEST first). Include date, asleep hours, efficiency%, optional midpoint.
- **TimelineView**: render in-bed vs asleep bars per night, normalized to max duration. Add an hours label.
- **SettingsView**: permission status, "Load Demo Data", "Export CSV" via ShareLink.

## Data layer already done
- HealthKit auth + observer + anchored fetch skeleton
- Demo data loader for Simulator
- Aggregation into `SleepNight` (duration, midpoint, efficiency)
- CSV export function

## Tips
- **Simulator**: HealthKit isn’t available → use "Load Demo Data".
- **Device**: add HealthKit capability + `NSHealthShareUsageDescription` in Info.plist.
- Sorting is **newest first** already in the view model.

## Acceptance Criteria
- Empty states are friendly and instructive.
- Trends & Timeline render meaningful info.
- Export produces a CSV.
- VoiceOver reads values on both screens.
