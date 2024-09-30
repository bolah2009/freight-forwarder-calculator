module WeightCalculators
  class BaseCalculator
    def calculate(_sailing)
      raise NotImplementedError, "Subclasses must implement the calculate method"
    end
  end
end
