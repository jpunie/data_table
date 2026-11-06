import {test} from "node:test"
import assert from "node:assert/strict"
import {DataTablePreferences} from "../assets/data_table_preferences.mjs"

function hook(storage) {
  const listeners = new Map()
  const calls = []
  globalThis.localStorage = storage
  const context = {
    el: {dataset: {tableId: "orders", preferenceKey: "data_table:orders"}},
    handleEvent(name, callback) {
      listeners.set(name, callback)
      return callback
    },
    removeHandleEvent(callback) {
      assert.equal(callback, listeners.get("data-table:preferences"))
      listeners.clear()
    },
    pushEventTo(...args) {
      calls.push(args)
      return Promise.resolve()
    }
  }
  return {context, listeners, calls}
}

test("restores, saves only its own events, and unregisters", () => {
  const data = new Map([["data_table:orders", '{"page_size":25,"visible_columns":["name"]}']])
  const {context, listeners, calls} = hook({
    getItem: key => data.get(key) ?? null,
    setItem: (key, value) => data.set(key, value)
  })
  DataTablePreferences.mounted.call(context)
  assert.deepEqual(calls, [[context.el, "restore-preferences", {page_size: 25, visible_columns: ["name"]}]])
  listeners.get("data-table:preferences")({id: "other", preferences: {page_size: 50}})
  assert.equal(JSON.parse(data.get("data_table:orders")).page_size, 25)
  listeners.get("data-table:preferences")({id: "orders", preferences: {page_size: null, visible_columns: []}})
  assert.deepEqual(JSON.parse(data.get("data_table:orders")), {page_size: null, visible_columns: []})
  DataTablePreferences.destroyed.call(context)
  assert.equal(listeners.size, 0)
})

test("reports invalid stored data and storage failures", () => {
  const errors = []
  const originalError = console.error
  console.error = (...args) => errors.push(args)
  try {
    const {context, listeners, calls} = hook({
      getItem: () => "{invalid",
      setItem: () => { throw new Error("storage unavailable") }
    })

    DataTablePreferences.mounted.call(context)
    assert.equal(calls.length, 0)
    listeners.get("data-table:preferences")({id: "orders", preferences: {}})
    assert.match(errors[0][0], /unable to read/)
    assert.match(errors[1][0], /unable to save/)
  } finally {
    console.error = originalError
  }
})

test("rejects JSON values that are not preference objects", () => {
  const originalError = console.error
  const errors = []
  console.error = (...args) => errors.push(args)
  try {
    const {context, calls} = hook({getItem: () => "null"})
    DataTablePreferences.mounted.call(context)
    assert.equal(calls.length, 0)
    assert.match(errors[0][1].message, /preferences must be an object/)
  } finally {
    console.error = originalError
  }
})
