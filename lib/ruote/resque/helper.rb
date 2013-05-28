# encoding: UTF-8

module Ruote
  module Resque

    class Helper

      def self.conditional_define(constant, value, parent = Object)
        if parent.const_defined? constant
          parent.const_get(constant)
        else
          parent.const_set(constant, value)
        end
      end

      def self.recursive_define(constant, value, parent = Object)

        arr = constant.split('::')
        first = arr.shift
        if arr.empty?
          self.conditional_define(first, value, parent)
        else
          self.recursive_define(arr.join('::'), value, self.conditional_define(first, Class.new, parent))
        end

      end

    end

  end
end
