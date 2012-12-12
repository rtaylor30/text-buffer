SelectList = require 'select-list'
{$$} = require 'space-pen'
$ = require 'jquery'

describe "SelectList", ->
  [selectList, array, list, miniEditor] = []

  beforeEach ->
    array = [
      ["A", "Alpha"], ["B", "Bravo"], ["C", "Charlie"],
      ["D", "Delta"], ["E", "Echo"], ["F", "Foxtrot"]
    ]

    selectList = new SelectList
    selectList.maxItems = 4
    selectList.filterKey = 1
    selectList.itemForElement = (element) ->
      $$ -> @li element[1], class: element[0]

    selectList.confirmed = jasmine.createSpy('confirmed hook')
    selectList.cancelled = jasmine.createSpy('cancelled hook')

    selectList.setArray(array)
    {list, miniEditor} = selectList

  describe "when an array is assigned", ->
    it "populates the list with up to maxItems items, based on the liForElement function", ->
      expect(list.find('li').length).toBe selectList.maxItems
      expect(list.find('li:eq(0)')).toHaveText 'Alpha'
      expect(list.find('li:eq(0)')).toHaveClass 'A'

  describe "when the text of the mini editor changes", ->
    beforeEach ->
      selectList.attachToDom()

    it "filters the elements in the list based on the scoreElement function and selects the first item", ->
      miniEditor.insertText('la')
      expect(list.find('li').length).toBe 2
      expect(list.find('li:contains(Alpha)')).toExist()
      expect(list.find('li:contains(Delta)')).toExist()
      expect(list.find('li:first')).toHaveClass 'selected'
      expect(selectList.error).not.toBeVisible()
      expect(selectList).not.toHaveClass("error")

    it "displays an error if there are no matches, removes error when there are matches", ->
      miniEditor.insertText('nothing will match this')
      expect(list.find('li').length).toBe 0
      expect(selectList.error).not.toBeHidden()
      expect(selectList).toHaveClass("error")

      miniEditor.setText('la')
      expect(list.find('li').length).toBe 2
      expect(selectList.error).not.toBeVisible()
      expect(selectList).not.toHaveClass("error")

  describe "when core:move-up / core:move-down are triggered on the miniEditor", ->
    it "selects the previous / next item in the list, or wraps around to the other side", ->
      expect(list.find('li:first')).toHaveClass 'selected'

      miniEditor.trigger 'core:move-up'

      expect(list.find('li:first')).not.toHaveClass 'selected'
      expect(list.find('li:last')).toHaveClass 'selected'

      miniEditor.trigger 'core:move-down'

      expect(list.find('li:first')).toHaveClass 'selected'
      expect(list.find('li:last')).not.toHaveClass 'selected'

      miniEditor.trigger 'core:move-down'

      expect(list.find('li:eq(0)')).not.toHaveClass 'selected'
      expect(list.find('li:eq(1)')).toHaveClass 'selected'

      miniEditor.trigger 'core:move-down'

      expect(list.find('li:eq(1)')).not.toHaveClass 'selected'
      expect(list.find('li:eq(2)')).toHaveClass 'selected'

      miniEditor.trigger 'core:move-up'

      expect(list.find('li:eq(2)')).not.toHaveClass 'selected'
      expect(list.find('li:eq(1)')).toHaveClass 'selected'

    it "scrolls to keep the selected item in view", ->
      selectList.attachToDom()
      itemHeight = list.find('li').outerHeight()
      list.height(itemHeight * 2)

      miniEditor.trigger 'core:move-down'
      miniEditor.trigger 'core:move-down'
      expect(list.scrollBottom()).toBe itemHeight * 3

      miniEditor.trigger 'core:move-down'
      expect(list.scrollBottom()).toBe itemHeight * 4

      miniEditor.trigger 'core:move-up'
      miniEditor.trigger 'core:move-up'
      expect(list.scrollBottom()).toBe itemHeight * 3

  describe "the core:confirm event", ->
    describe "when there is an item selected (because the list in not empty)", ->
      it "triggers the selected hook with the selected array element", ->
        miniEditor.trigger 'core:move-down'
        miniEditor.trigger 'core:move-down'
        miniEditor.trigger 'core:confirm'
        expect(selectList.confirmed).toHaveBeenCalledWith(array[2])

    describe "when there is no item selected (because the list is empty)", ->
      it "does not trigger the confirmed hook", ->
        miniEditor.insertText("i will never match anything")
        expect(list.find('li')).not.toExist()
        miniEditor.trigger 'core:confirm'
        expect(selectList.confirmed).not.toHaveBeenCalled()

  describe "when a list item is clicked", ->
    it "selects the item on mousedown and confirms it on mouseup", ->
      item = list.find('li:eq(1)')

      item.mousedown()
      expect(item).toHaveClass 'selected'
      item.mouseup()

      expect(selectList.confirmed).toHaveBeenCalledWith(array[1])

  describe "the core:cancel event", ->
    it "triggers the cancelled hook and detaches the select list", ->
      spyOn(selectList, 'detach')
      miniEditor.trigger 'core:cancel'
      expect(selectList.cancelled).toHaveBeenCalled()
      expect(selectList.detach).toHaveBeenCalled()

  describe "when the mini editor loses focus", ->
    it "triggers the cancelled hook and detaches the select list", ->
      spyOn(selectList, 'detach')
      miniEditor.trigger 'focusout'
      expect(selectList.cancelled).toHaveBeenCalled()
      expect(selectList.detach).toHaveBeenCalled()

  describe "when an error occurs on previously populated list", ->
    it "clears the list", ->
      selectList.setError("yolo")
      expect(selectList.list).toBeEmpty()

  describe "when loading is triggered on previously populated list", ->
    it "clears the list", ->
      selectList.setLoading("loading yolo")
      expect(selectList.list).toBeEmpty()
