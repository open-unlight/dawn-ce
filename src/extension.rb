# frozen_string_literal: true

# TODO: Remove monkey patch
class String
  def blank?
    self.length == 0
  end
end

class Array
  def blank?
    self.length == 0
  end
end

class Integer
  def blank?
    self == 0
  end
end

class NilClass
  def blank?
    true
  end
end
