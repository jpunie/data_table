defmodule DataTable.Gettext do

  def gettext(nil, key) do
    key
  end

  def gettext(gettext, key) do
    Gettext.gettext(gettext, key)
  end

end
