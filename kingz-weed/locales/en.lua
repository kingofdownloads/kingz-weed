local Translations = {
    error = {
        not_owner = 'This is not your plant',
        no_water = 'You need a water bottle',
        no_fertilizer = 'You need fertilizer',
        no_pesticide = 'You need pesticide',
        no_bugs = 'This plant doesn\'t have bugs',
        not_ready = 'This plant is not ready to harvest yet',
        canceled = 'Canceled',
        no_weed = 'You don\'t have any weed'
    },
    success = {
        watered = 'Plant watered successfully',
        fertilized = 'Plant fertilized successfully',
        pesticide_applied = 'Pesticide applied successfully',
        bugs_removed = 'Bugs removed successfully',
        harvested = 'Plant harvested successfully',
        processed = 'Processing complete',
        sold = 'Sold %{amount}x %{item} for $%{price}'
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
