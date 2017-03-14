require_relative "../../test_helper"

module SmartAnswer::Calculators
  class PayLeaveForParentsDataQueryTest < ActiveSupport::TestCase
    context PayLeaveForParentsDataQuery do
      setup do
        @query = PayLeaveForParentsDataQuery.new
      end

      context "statutory_parental_pay" do
        should "find statutory_parental_pay for the current year" do
          assert_equal '139.58', @query.statutory_parental_pay
        end

        should "get the start date for the current rate" do
          assert_equal Date.parse("2016-04-06"), @query.start_date
        end

        should "get the end date for the current rate" do
          assert_equal Date.parse("2017-04-05"), @query.end_date
        end

        should "be able to format the date properly" do
          assert_equal "6 April 2016", @query.start_date.strftime("%-d %B %Y")
          assert_equal "5 April 2017", @query.end_date.strftime("%-d %B %Y")
        end
      end
    end
  end
end
