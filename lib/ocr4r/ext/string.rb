class String
  def ord
    self[0]
  end unless respond_to?(:ord)
end