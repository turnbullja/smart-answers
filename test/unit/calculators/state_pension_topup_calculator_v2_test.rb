require_relative "../../test_helper"

module SmartAnswer::Calculators
  class StatePensionTopupCalculatorTest < ActiveSupport::TestCase
    context "checking lump sum amount" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionTopupCalculator.new
      end

      should "be 8010 for age of 69" do
        assert_equal 8010, @calculator.lump_sum_amount(69, 10)
      end

      should "be nil for age of 101" do
        assert_equal 0, @calculator.lump_sum_amount(101, 20)
      end

      should "be 2,720 for age of 80" do
        assert_equal 2720, @calculator.lump_sum_amount(80, 5)
      end
    end

    context "check lump sum amount and age" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionTopupCalculator.new
      end

      should "Show age of 64" do
        assert_equal 64, @calculator.date_difference_in_years(Date.parse('1951-04-06'), Date.parse('2015-10-12'))
      end

      should "Show age of 85" do
        assert_equal 85, @calculator.date_difference_in_years(Date.parse('1930-04-06'), Date.parse('2015-10-12'))
      end
    end

    context "check return value for lump sum amount and age male" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionTopupCalculator.new
        @calculator.retirement_age('male')
      end

      should "Show 3 rates for ages 85 to 87" do
        assert_equal [{:amount=>3940.0, :age=>85}, {:amount=>3660.0, :age=>86}, {:amount=>3390.0, :age=>87}], @calculator.lump_sum_and_age(Date.parse('1930-04-06'), 10)
      end

      should "Show 2 rates for ages 65 and 66" do
        assert_equal [{:amount=>8900.0, :age=>65}, {:amount=>8710.0, :age=>66}], @calculator.lump_sum_and_age(Date.parse('1951-04-06'), 10)
      end
    end

    context "check return value for lump sum amount and age female" do
      setup do
        @calculator = SmartAnswer::Calculators::StatePensionTopupCalculator.new
        @calculator.retirement_age('female')
      end

      should "Show 2 rates for 63 and 64" do
        assert_equal [{:amount=>9340.0, :age=>63}, {:amount=>9130.0, :age=>64}], @calculator.lump_sum_and_age(Date.parse('1953-04-06'), 10)
      end
    end
  end
end
