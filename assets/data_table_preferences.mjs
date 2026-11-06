export const DataTablePreferences = {
  mounted() {
    this.preferencesListener = this.handleEvent("data-table:preferences", ({id, preferences}) => {
      if (String(id) !== this.el.dataset.tableId) return

      try {
        localStorage.setItem(this.el.dataset.preferenceKey, JSON.stringify(preferences))
      } catch (error) {
        console.error("DataTable: unable to save preferences", error)
      }
    })

    try {
      const saved = localStorage.getItem(this.el.dataset.preferenceKey)
      if (saved !== null) {
        const preferences = JSON.parse(saved)
        if (preferences === null || typeof preferences !== "object" || Array.isArray(preferences)) {
          throw new TypeError("preferences must be an object")
        }
        this.pushEventTo(this.el, "restore-preferences", preferences).catch(error => {
          console.error("DataTable: unable to restore preferences", error)
        })
      }
    } catch (error) {
      console.error("DataTable: unable to read preferences", error)
    }
  },

  destroyed() {
    this.removeHandleEvent(this.preferencesListener)
  }
}
