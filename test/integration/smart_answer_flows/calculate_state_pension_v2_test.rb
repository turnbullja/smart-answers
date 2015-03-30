require_relative '../../test_helper'
require_relative 'flow_test_helper'

class CalculateStatePensionV2Test < ActiveSupport::TestCase
  include FlowTestHelper

  setup do
    setup_for_testing_flow 'calculate-state-pension-v2'
  end

  should "ask which calculation to perform" do
    assert_current_node :which_calculation?
  end

  # #Age
  context "age calculation" do
    setup do
      add_response :age
    end

    should "ask your gender" do
      assert_current_node :gender?
    end

    context "male" do
      setup do
        add_response :male
      end

      should "ask for date of birth" do
        assert_current_node :dob_age?
      end

      context "give a date in the future" do
        should "raise an error" do
          add_response (Date.today + 1).to_s
          assert_current_node_is_error
        end
      end

      context "pension_credit_date check -- born 5th Dec 1953" do
        setup { add_response Date.parse("5th Dec 1953")}
        should "go to age result" do
          assert_current_node :age_result
          assert_state_variable :state_pension_date, Date.parse("05 Dec 2018")
          assert_state_variable :pension_credit_date, Date.parse("06 Nov 2018").strftime("%-d %B %Y")
          assert_phrase_list :state_pension_age_statement, [:state_pension_age_is_a, :pension_credit_future, :pension_age_review, :bus_pass]
        end
      end

      context "age is less than 20 years" do
        should "user is too young to get more information" do
          add_response Date.today.advance(years: -15)

          assert_current_node :too_young
        end
      end

      context "age is between 4 months and 1 day from SP age" do
        setup do
          Timecop.travel("2013-07-15")
        end

        should "state that user is near state pension age when born on 16th July 1948" do
          add_response Date.parse("16 July 1948") # retires 16 July 2013
          assert_current_node :near_state_pension_age
          assert_phrase_list :pension_credit, [:pension_credit_past]
        end

        should "state that user is near state pension age when born on 14th November 1948" do
          add_response Date.parse("14 November 1948") # retires 14 Nov 2013
          assert_current_node :near_state_pension_age
          assert_phrase_list :pension_credit, [:pension_credit_past]
        end
      end

      context "born on 6th April 1945" do
        setup do
          add_response Date.parse("6th April 1945")
        end

        should "give an answer" do
          assert_current_node :age_result
          assert_phrase_list :tense_specific_title, [:have_reached_pension_age]
          assert_phrase_list :state_pension_age_statement, [:state_pension_age_was, :pension_credit_past, :bus_pass]
          assert_state_variable "state_pension_age", "65 years"
          assert_state_variable "formatted_state_pension_date", "6 April 2010"
        end
      end # born on 6th of April

      context "born on 5th November 1948" do
        setup do
          Timecop.travel("2013-07-22")
          add_response Date.parse("1948-11-05")
        end

        should "be near to the state pension age" do
          assert_state_variable :available_ni_years, 45
          assert_current_node :near_state_pension_age
          assert_phrase_list :pension_credit, [:pension_credit_past]
        end
      end

      context "two days ahead of date in July 2013" do
        setup do
          Timecop.travel("2013-07-24")
          add_response Date.parse("1948-07-26")
        end

        should "tell the user that they're near state pension age" do
          assert_current_node :near_state_pension_age
          assert_phrase_list :pension_credit, [:pension_credit_past]
        end
      end
    end # male

    context "female, born on 4 August 1951" do
      setup do
        Timecop.travel('2012-10-08')
        add_response :female
        add_response Date.parse("4th August 1951")
      end

      should "tell them they are within four months and one day of state pension age" do
        assert_current_node :near_state_pension_age
        assert_state_variable "formatted_state_pension_date", "6 November 2012"
      end
    end

    context "female born on 1 July 1956, timecop day before near_state_pension_age" do
      setup do
        Timecop.travel('2014-05-06')
        add_response :female
        add_response Date.parse('1 July 1952')
      end

      should "show result for state_pension_age_is outcome" do
        assert_current_node :age_result
        assert_phrase_list :state_pension_age_statement, [:state_pension_age_is, :pension_credit_future, :bus_pass]
      end
    end

    context "additional coverage for birthdate 6 March 1961" do
      setup do
        Timecop.travel('2014-05-07')
      end
      should "go to correct outcome" do
        add_response :male
        add_response Date.parse('6 March 1961')
        assert_current_node :age_result
        assert_phrase_list :state_pension_age_statement, [:state_pension_age_is_a, :pension_credit_future, :pension_age_review, :bus_pass]
      end
    end

    context "male with different state pension and pension credit dates" do
      setup do
        Timecop.travel('2014-05-07')
      end
      should "go to correct outcome with pension_credit_past" do
        add_response :male
        add_response Date.parse('3 February 1952')
        assert_current_node :age_result
        assert_state_variable :formatted_state_pension_date, '3 February 2017'
        assert_state_variable :pension_credit_date, '6 November 2013'
        assert_phrase_list :state_pension_age_statement, [:state_pension_age_is_a, :pension_credit_past, :pension_age_review, :bus_pass]
      end
    end

    context "test correct state pension age" do
      setup do
        Timecop.travel('2014-05-08')
      end
      should "show state pension age of 60 years" do
        add_response :female
        add_response Date.parse('23 April 1949')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "60 years"
      end

      should "show state pension age of 65 years" do
        add_response :male
        add_response Date.parse('23 April 1951')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "65 years"
      end

      should "show state pension age of 66 years" do
        add_response :male
        add_response Date.parse('23 October 1954')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "66 years"
      end

      should "show state pension age of 66 years, 1 month" do
        add_response :male
        add_response Date.parse('23 April 1960')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "66 years, 1 month"
      end

      should "show state pension age of 66 years, 10 month" do
        add_response :male
        add_response Date.parse('23 January 1961')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "66 years, 10 months"
      end

      should "show state pension age of 67" do
        add_response :male
        add_response Date.parse('23 March 1969')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "67 years"
      end

      should "show state pension age of 68" do
        add_response :male
        add_response Date.parse('23 March 1978')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "67 years, 11 months, 11 days"
      end

      should "should show 67 years old as state pension age" do
        add_response :female
        add_response Date.parse('1968-04-07')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "67 years"
      end

      should "should also show 67 years old" do
        add_response :male
        add_response Date.parse('1969-03-07')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, "67 years"
      end

      should "show the correct number of days for people born on 29th February" do
        add_response :female
        add_response Date.parse('29 February 1952')
        assert_current_node :age_result
        assert_state_variable :state_pension_age, '61 years, 10 months, 7 days'
      end
    end
  end # age calculation

  #Amount
  #
  context "amount calculation" do
    setup do
      add_response :amount
    end

    should "ask your gender" do
      assert_current_node :gender?
    end

    context "male" do
      setup {add_response :male}

      should "ask for date of birth" do
        assert_current_node :dob_amount?
      end

      context 'between 7 and 10 years NI including credits
               born within automatic NI age group (1959-04-06 - 1992-04-05)' do
        setup do
          add_response Date.parse('1971-08-02')
          add_response 8
          add_response 0
          add_response :no
        end

        should "take me to Amount Result without asking Have you lived or worked outside the UK?" do
          assert_current_node :amount_result
        end
      end

      context 'Born after 1992-04-05' do
        context "more than 10 years NI contributions" do
          setup do
            Timecop.travel('2030-04-06')
            add_response Date.parse('1999-04-06')
            add_response 11
            add_response 0
            add_response :no
          end

          should "take me to years of work" do
            assert_current_node :years_of_work?
          end
        end

        context "less than 10 years NI contributions" do
          setup do
            add_response Date.parse('1992-04-06')
            add_response 0
            add_response 0
            add_response :no
          end

          should "take me to lived years of work" do
            assert_current_node :years_of_work?
          end
        end
      end

      context "give a date in the future" do
        should "raise an error" do
          add_response (Date.today + 1).to_s
          assert_current_node_is_error
        end
      end

      context "within four months and one day of state pension age test" do
        setup do
          Timecop.travel('2012-10-08')
          add_response Date.parse('1948-02-09')
        end

        should "ask for how many years National Insurance has been paid" do
          assert_current_node :years_paid_ni?
        end
      end

      context "born 28th July 2013 and running on 25th July 2013" do
        setup do
          Timecop.travel("2013-07-25")
          add_response Date.parse("1948-07-28")
        end

        should "ask for how many years National Insurance has been paid" do
          assert_current_node :years_paid_ni?
        end
      end

      context "four months and five days from state pension age test" do
        setup do
          Timecop.travel('2012-10-08')
          add_response Date.parse('1948-02-13')
        end

        should "ask for years paid ni" do
          assert_state_variable :ni_years_to_date_from_dob, 45
          assert_current_node :years_paid_ni?
        end
      end

      context "older than 20 years from state pension date" do
        setup do
          Timecop.travel('2012-10-08')
          add_response Date.parse('1968-02-13')
        end

        should "ask for years paid ni" do
          assert_state_variable :ni_years_to_date_from_dob, 25
          assert_current_node :years_paid_ni?
        end
      end

      context "born before 6/10/1953" do
        setup do
          Timecop.travel('2013-10-08')
          add_response Date.parse("4th October 1953")
        end

        should "ask for number of years paid NI" do
          assert_state_variable "state_pension_age", "65 years"
          assert_current_node :years_paid_ni?
        end

        context "25 years of NI" do
          setup do
            add_response 25
          end

          should "ask for JSA years" do
            assert_current_node :years_of_jsa?
          end

          context "1 year of JSA" do
            setup do
              add_response 1
            end

            should "ask about child benefit " do
              assert_state_variable "qualifying_years", 26
              assert_current_node :received_child_benefit?
            end

            context "yes to child benefit" do
              setup do
                add_response :yes
              end

              should "ask for years of child benefit" do
                assert_current_node :years_of_benefit?
              end

              context "4 years of child benefit" do
                setup do
                  add_response 4
                end

                should "ask for years of additional benefits" do
                  assert_current_node :years_of_caring?
                end

                context "2 years of additional benefits" do
                  setup do
                    add_response 2
                  end

                  should "ask years of carer's allowance" do
                    assert_current_node :years_of_carers_allowance?
                  end

                  context "2 years of carer's allowance" do
                    setup do
                      add_response 2
                    end

                    should "ask years of work between 16 and 19" do
                      assert_current_node :years_of_work?
                    end

                    context "0 years of work between 16 and 19" do
                      setup do
                        add_response 0
                      end

                      should "go to amount_result" do
                        assert_state_variable "qualifying_years_total", 34
                        assert_current_node :amount_result
                      end
                    end
                  end # 2 years of carer's allowance
                end # 2 years additional benefit
              end # 4 years of child benefit

              should "error on text entry" do
                add_response 'four years'
                assert_current_node_is_error
              end

              should "error on amount over 22" do
                add_response 44
                assert_current_node_is_error
              end

              context "add 2 years of child benefit" do
                setup do
                  add_response 2
                end

                should "go to years of care" do
                  assert_state_variable "qualifying_years", 28
                  assert_current_node :years_of_caring?
                end
              end # 2 years if child benefit

              context "0 years of child benefit" do
                setup {add_response 0}

                should "go to years of caring" do
                  assert_state_variable "qualifying_years", 26
                  assert_current_node :years_of_caring?
                end

                context "0 years_of_caring" do
                  setup {add_response 0}

                  should "go to years_of_carers_allowance" do
                    assert_current_node :years_of_carers_allowance?
                  end

                  context "0 years_of_carers_allowance" do
                    setup {add_response 0}

                    should "go years_of_work" do
                      assert_current_node :years_of_work?
                    end

                    context "0 years_of_work" do
                      setup {add_response 0}

                      should "go to amount_result" do
                        assert_state_variable "qualifying_years", 26
                        assert_state_variable "qualifying_years_total", 26
                        assert_state_variable "missing_years", 4
                        assert_state_variable "pension_amount", "95.46" # 26/30 * 110.15
                        assert_state_variable "state_pension_age", "65 years"
                        assert_state_variable "remaining_years", 5
                        assert_state_variable "pension_loss", "14.69"
                        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a, :automatic_years_phrase]
                        assert_state_variable "state_pension_date", Date.parse("2018 Oct 4th")
                        assert_current_node :amount_result
                      end
                    end #work
                  end #carers allowance
                end # caring
              end # 0 years of child benefit
            end # yes to child benefit
          end # 1 year of JSA
        end # 25 years of NI

        context "when date is 1 November 2012" do

          context "NI = 20, JSA = 1 received_child_benefit = yes, years_of_benefit = 1, years_of_caring = 1" do
            setup do
              Timecop.travel('2012-11-01')
              add_response 20
              add_response 1
              add_response :yes
              add_response 1
            end

            should "be on years_of_caring" do
              assert_state_variable "qualifying_years", 22
              assert_current_node :years_of_caring?
            end

            context "answer 1 year" do
              setup do
                add_response 1
              end

              should "be on years_of_carers_allowance" do
                assert_state_variable "qualifying_years", 23
                assert_current_node :years_of_carers_allowance?
              end

              should "be on years_of_work" do
                add_response 1
                assert_state_variable "qualifying_years", 24
                assert_current_node :years_of_work?
              end
            end

            should "throw error on years_of_caring = 3 before 6 april 2013" do
              add_response 3
              assert_current_node_is_error
            end
          end # ni=20, jsa=1, etc...
        end # when date was 1 Nov 2012

        context "when date is 6 April 2013, NI = 15, JSA = 1 received_child_benefit = yes, years_of_benefit = 1" do
          setup do
            Timecop.travel('2013-04-06')
            add_response 15 #ni
            add_response 1 #jsa
            add_response :yes #
            add_response 1 #benefit
          end

          should "not allow 4 years of caring before 6 April 2014" do
            add_response 4 #years of caring
            assert_current_node_is_error
          end

          should "allow 3 years of caring on 6 April 2013" do
            add_response 3
            assert_current_node :years_of_carers_allowance?
          end
        end

      end # born before 6/10/1953

      context "age 61, NI = 15 (testing years_of_jsa errors)" do
        setup do
          add_response 61.years.ago
          add_response 15
        end

        should "error when entering more than 27" do
          add_response 28
          assert_current_node_is_error
        end

        should "pass when entering 7" do
          add_response 7
          assert_current_node :received_child_benefit?
        end
      end # 61, ni=15, etc

      context "age = 61, NI = 20, JSA = 1" do
        setup do
          Timecop.travel("2012-08-08")
          add_response Date.civil(61.years.ago.year, 4, 7)
          add_response 20
          add_response 1
        end

        should "go to received_child_benefit?" do
          assert_state_variable "available_ni_years", 21
          assert_state_variable "qualifying_years", 21
          assert_current_node :received_child_benefit?
        end

        context "answer yes" do
          setup {add_response :yes}

          should "be at years_of_benefit" do
            assert_current_node :years_of_benefit?
          end

          should "error if 23 years entered" do
            add_response 23
            assert_current_node_is_error
          end

          context "2 years of benefit" do
            setup {add_response 2}

            should "available_ni_years = 19, qualifying_years = 23" do
              assert_state_variable "available_ni_years", 19
              assert_state_variable "qualifying_years", 23
              assert_current_node :years_of_caring?
            end
          end
        end
      end # 61, ni=10, jsa=1, etc

      context "starting credits test 1" do
        setup do
          add_response Date.parse('1962-03-06')
          add_response 20
          add_response 7
          add_response "yes"
          add_response 5
          add_response 0
          add_response 0
        end

        should "display result including starting credits" do
          assert_state_variable :qualifying_years_total, 35
          assert_current_node :amount_result
          assert_phrase_list :automatic_credits, [:automatic_credits]
        end
      end
      context "starting credits test 2" do
        setup do
          add_response Date.parse('1957-04-06')
          add_response 28
          add_response 1
          add_response "no"
          add_response 3
        end
        should "display result because of starting credits" do
          assert_state_variable :qualifying_years_total, 32
          assert_current_node :amount_result
          assert_phrase_list :automatic_credits, [:automatic_credits]
        end
      end

      context "is state pension age" do
        setup do
          Timecop.travel("2013-07-18")
          add_response Date.parse("1948-07-18")
        end

        should "should show the result and have the state pension age assigned" do
          assert_state_variable :state_pension_age, "65 years"
          assert_current_node :reached_state_pension_age
        end
      end
    end # male

    context "female" do
      setup do
        Timecop.travel('2014-05-06')
        add_response :female
      end

      should "ask for date of birth" do
        assert_current_node :dob_amount?
      end

      context "under 20 years old" do
        should "say not enough qualifying years" do
          add_response 5.years.ago
          assert_current_node :too_young
        end
      end

      context "90 years old" do
        should "say already reached state pension age" do
          add_response 90.years.ago
          assert_current_node :reached_state_pension_age
        end
      end

      context "50 years old" do
        setup do
          Timecop.travel('2012-10-08')
          add_response Date.civil(50.years.ago.year, 4, 7)
        end

        should "ask for number of years paid NI" do
          assert_state_variable :remaining_years, 17
          assert_state_variable :ni_years_to_date_from_dob, 31
          assert_current_node :years_paid_ni?
        end

        context "30 years of NI" do
          should "show the result" do
            add_response 30
            add_response 0 # unemployment
            add_response 'no' # claimed benefits
            assert_current_node :amount_result
          end
        end

        context "27 years of NI" do
          setup do
            add_response 37
          end

          should "return error as they will only have available_ni_years of 21" do
            assert_current_node_is_error
          end
        end

        context "10 years of NI" do
          setup do
            add_response 10
          end

          should "ask for number of years claimed JSA" do
            assert_state_variable "available_ni_years", 21
            assert_current_node :years_of_jsa?
          end

          context "7 years of jsa" do
            should "show the result" do
              add_response 7
              assert_state_variable "available_ni_years", 14
              assert_current_node :received_child_benefit?
            end
          end

          context "1 year of jsa" do
            setup do
              add_response 1
            end

            should "ask for years of benefit" do
              assert_current_node :received_child_benefit?
            end
          end
        end
      end

      context "born between 1959-04-06 or 1992-04-05, not enough qualifying years, no child benefit" do
        setup do
          Timecop.travel('2014-05-06')
        end
        should "return amount_result" do
          add_response Date.parse("8th October 1960")
          add_response :yes
          add_response 25   # ni years
          add_response 1    # jsa years
          add_response :no
          assert_current_node :amount_result
          assert_phrase_list :automatic_credits, [:automatic_credits]
        end
      end

      context "born after 6/10/1953 and 25 years of taxed income" do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse("8th October 1953")
          add_response :no
          add_response 25
        end

        context "not enough qualifying years" do
          setup do
            add_response 1
          end

          should "get to received_child_benefit?" do
            assert_current_node :received_child_benefit?
          end

          context "not received child benefit" do
            setup do
              add_response :no
            end

            should "go to years_of_work" do
              assert_current_node :years_of_work?
            end

            context "no years of work between 16 and 19" do
              setup do
                add_response 0
              end

              should "go to outcome" do
                assert_current_node :amount_result
              end
            end
          end

          context "yes have received child benefit" do
            setup do
              add_response :yes
            end

            should "go to years_of_benefit" do
              assert_current_node :years_of_benefit?
            end
          end

        end

        context "enough qualifying years" do
          setup do
            Timecop.travel('2014-05-06')
          end
          should "answer all and go to correct outcome" do
            add_response 1
            add_response "yes"
            add_response 5
            add_response 4
            add_response 2
            add_response 0
            assert_current_node :amount_result
            assert_state_variable :automatic_credits, ''
          end
        end
      end

      context "(testing from years_of_benefit) age 40, NI = 5, JSA = 5, cb = yes " do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.civil(40.years.ago.year, 4, 7)
          add_response 10
          add_response 5
          add_response :yes
        end

        should "error when entering more than 6 (over available_ni_years limit)"  do
          add_response 7
          assert_current_node_is_error
        end

        should "pass when entering 6 (go to amount_result as available_ni_years is maxed)" do
          add_response 6
          assert_current_node :amount_result
        end

        context "answer 0" do
          setup {add_response 0}

          should "be at years_of_caring?" do
            assert_state_variable "available_ni_years", 6
            assert_current_node :years_of_caring?
          end

          should "fail on 5" do
            add_response 5
            assert_current_node_is_error
          end

          should "pass when entering 4" do
            add_response 4
            add_response 2
            assert_current_node :amount_result
          end

          context "answer 0" do
            setup {add_response 0}

            should "go to years_of_carers_allowance" do
              assert_state_variable "available_ni_years", 6
              assert_current_node :years_of_carers_allowance?
            end

            should "fail on 17" do
              add_response 17
              assert_current_node_is_error
            end

            should "pass when entering 1 (go to amount_result as available_ni_years is maxed)" do
              add_response 1
              assert_current_node :amount_result
            end

            context "answer 0" do
              setup {add_response 0}

              should "got to years_of_work?" do
                assert_state_variable "available_ni_years", 6
                assert_current_node :amount_result
              end
            end
          end
        end
      end

      context "(testing from years_of_work) born in '58, NI = 20, JSA = 7, cb = no " do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse("5th May 1958")
          add_response :yes
          add_response 20
          add_response 7
          add_response :no
        end

        should "be at years_of_work" do
          assert_current_node :years_of_work?
        end

        should "return error on entering 4" do
          add_response 4
          assert_current_node_is_error
        end

        should "return amount_result on entering 3" do
          add_response 3
          assert_current_node :amount_result
        end
      end

      ## Too old for automatic age related credits.
      context "58 years old" do
        setup do
          add_response 58.years.ago
          add_response :no
        end

        should "ask for number of years paid NI" do
          assert_current_node :years_paid_ni?
        end

        context "39 years of NI and no years worked 16 - 19" do
          should "show the result" do
            add_response 39
            add_response 0 # 16 - 19 years worked
            assert_current_node :amount_result
          end
        end

        context "27 years of NI" do
          setup do
            add_response 27
          end

          should "ask for number of years claimed JSA" do
            assert_current_node :years_of_jsa?
          end

          context "10 years of jsa and no 16 - 19 years worked" do
            should "show the result" do
              add_response 12
              add_response 0 # 16 - 19 years worked
              assert_current_node :amount_result
            end
          end

          context "1 year of jsa" do
            setup do
              add_response 1
            end

            should "ask if received child benefit" do
              assert_current_node :received_child_benefit?
            end
          end #years of jsa
        end #years of NI
      end # years old

      context "answer born Jan 1st 1970" do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse('1970-01-01')
          add_response 20
          add_response 0
          add_response :no
        end

        should "add 3 years credit for a person born between 1959 and 1992" do
          assert_current_node :amount_result
          assert_state_variable "missing_years", 7
        end
      end

      context "answer born Jan 1st 1959" do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse('1959-01-01')
          add_response :yes
          add_response 20
          add_response 4
          add_response :yes
          add_response 2
          add_response 1
          add_response 0
          add_response 0
        end

        should "add 2 years credit for a person born between April 1958 and April 1959" do
          assert_current_node :amount_result
          assert_state_variable "missing_years", 1
        end
      end
      context "answer born December 1st 1957" do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse('1957-12-01')
          add_response :no
          add_response 20
          add_response 0
          add_response :no
          add_response 0
        end

        should "add 1 year credit for a person born between April 1957 and April 1958" do
          assert_state_variable "missing_years", 9
        end
      end
      context "years_you_can_enter test" do
        setup do
          add_response Date.civil(49.years.ago.year, 4, 7)
          add_response 20
          add_response 5
          add_response :yes
        end

        should "return 5" do
          assert_state_variable "available_ni_years", 5
          assert_state_variable "years_you_can_enter", 5
          assert_current_node :years_of_benefit?
        end
      end

      context "starting credits test 2" do
        setup do
          Timecop.travel('2014-05-06')
          add_response Date.parse('1964-12-06')
          add_response 27
          add_response 3 # unemployment, sickeness
        end

        should "add starting credits and go to results" do
          assert_state_variable :qualifying_years_total, 33
          assert_current_node :amount_result
        end
      end
    end # female

    context "testing flow optimisation - at least 2 SC years" do
      setup do
        Timecop.travel('2014-05-06')
        add_response 'female'
        add_response Date.parse('1958-05-10')
        add_response :yes
        add_response 34
        add_response 0 # unemployment, sickness
        add_response 'no' # child benefit
        add_response 0 # 16 - 19 working years
      end

      should "gets starting credits and through to result" do
        assert_current_node :amount_result
      end
    end

    context "testing flow optimisation - at least 1 SC year" do
      setup do
        Timecop.travel('2014-05-06')
        add_response 'male'
        add_response Date.parse('1957-11-26')
        add_response 35
        add_response 1 # unemployment, sickness
        add_response 'no' # child benefit
        add_response 3 # 16 - 19 working years
      end

      should "gets starting credits and through to result" do
        assert_current_node :amount_result
      end
    end

    context "testing flow optimisation - 3 SC years" do
      setup do
        Timecop.travel('2014-05-06')
        add_response 'male'
        add_response Date.parse('1960-02-08')
        add_response 25
        add_response 7 # unemployment, sickness
        add_response 'no' # child benefit
      end

      should "gets starting credits and through to result" do
        assert_current_node :amount_result
      end
    end

    context "within 4 months and 1 day of SPA, has enough qualifying years" do
      setup do
        Timecop.travel('2013-06-26')
        add_response 'male'
        add_response Date.parse('1948-08-09')
        add_response 30
      end
      should "display close to SPA outcome" do
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 30
        assert_state_variable "state_pension_age", "65 years"
        assert_state_variable "formatted_state_pension_date", " 9 August 2013"
        assert_phrase_list :result_text, [:within_4_months_enough_qy_years, :pension_statement, :within_4_months_enough_qy_years_more]
      end
    end

    context "within 35 days of SPA, has enough qualifying years" do
      setup do
        Timecop.travel('2013-07-05')
        add_response 'male'
        add_response Date.parse('1948-08-09')
        add_response 30
      end
      should "display close to SPA outcome without pension statement" do
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 30
        assert_state_variable "state_pension_age", "65 years"
        assert_state_variable "formatted_state_pension_date", " 9 August 2013"
        assert_phrase_list :result_text, [:within_4_months_enough_qy_years, :within_4_months_enough_qy_years_more]
      end
    end

    context "within 4 months and 1 day of SPA, doesn't have enough qualifying years" do
      setup do
        Timecop.travel('2013-06-26')
        add_response 'male'
        add_response Date.parse('1948-08-09')
        add_response 20
        add_response 3
        add_response 'no'
        add_response 0
      end
      should "display close to SPA outcome" do
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 23
        assert_state_variable "state_pension_age", "65 years"
        assert_state_variable "formatted_state_pension_date", " 9 August 2013"
        assert_phrase_list :result_text, [:within_4_months_not_enough_qy_years, :pension_statement, :within_4_months_not_enough_qy_years_more, :automatic_years_phrase]
      end
    end

    context "within 35 days of SPA, doesn't have enough qualifying years" do
      setup do
        Timecop.travel('2013-07-05')
        add_response 'male'
        add_response Date.parse('1948-08-09')
        add_response 20
        add_response 3
        add_response 'no'
        add_response 0
      end
      should "display close to SPA outcome without pension statement" do
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 23
        assert_state_variable "state_pension_age", "65 years"
        assert_state_variable "formatted_state_pension_date", " 9 August 2013"
        assert_phrase_list :result_text, [:within_4_months_not_enough_qy_years, :within_4_months_not_enough_qy_years_more, :automatic_years_phrase]
      end
    end

    context "people one day away from state pension with different birthdays" do
      # The following tests use values from factchecks around 5/9/13
      setup do
        Timecop.travel('5 Sep 2013')
        add_response 'female'
      end
      should "should show the correct result" do
        add_response Date.parse('4 Jan 1952')
        add_response 25
        add_response 5

        assert_state_variable "formatted_state_pension_date", " 6 September 2013"
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:within_4_months_enough_qy_years, :within_4_months_enough_qy_years_more]
      end

      should "should show the correct result with pay_reduced_ni_rate" do
        add_response Date.parse('6 Dec 1951')
        add_response 10
        add_response 15
        add_response 'yes'
        add_response 2
        add_response 3

        assert_state_variable "formatted_state_pension_date", " 6 September 2013"
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:within_4_months_enough_qy_years, :within_4_months_enough_qy_years_more]
      end

      context "for someone who has reached state pension age" do
        should "display the correct result" do
          add_response Date.parse('15 July 1945')

          assert_current_node :reached_state_pension_age
        end
      end
    end

    context "set timecop for tests" do
      setup do
        Timecop.travel('2014-05-06')
      end

      should "should show results for less than ten years NI" do
        add_response :male
        add_response Date.parse('1 Jan 1978')
        add_response 5
        add_response 0
        add_response 'no'
        add_response 'no'
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :less_than_ten, :too_few_qy_enough_remaining_years_a]
      end # less than 10 years NI

      should "show results for not enough qualifyting but enough remaining years" do
        add_response :male
        add_response Date.parse('1 Jan 1953')
        add_response 20
        add_response 0
        add_response 'no'
        add_response 0
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a, :automatic_years_phrase]
      end

      should "show results form additional HMRC test case" do
        add_response :female
        add_response Date.parse('6 April 1958')
        add_response :no
        add_response 31
        add_response 0
        add_response 'yes'
        add_response 5
        add_response 0
        add_response 0
        add_response 3
        assert_current_node :amount_result
      end
    end

    context "Timecop date set to 30 April 2014" do
      setup do
        Timecop.travel('2014-04-30')
      end

      should "show results for male and 44 available years" do
        add_response :male
        add_response Date.parse('6 April 1951')
        add_response 33
        add_response 4 # unemployment, sickness
        add_response 'no' # child benefit
        add_response 2 # 16 - 19 working years
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 39
        assert_state_variable :remaining_years, 2
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a, :automatic_years_phrase]
      end

      should "show results for female and 40 available years" do
        add_response :female
        add_response Date.parse('12 November 1954')
        add_response :yes
        add_response 38
        add_response 1 # unemployment, sickness
        add_response 'yes' # child benefit
        add_response 1 # years of benefit
        add_response 2 # 16 - 19 work
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 42
        assert_state_variable :remaining_years, 6
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a]
      end

      should "show results for female and 29 available years" do
        add_response :female
        add_response Date.parse('6 December 1965')
        add_response 25
        add_response 4 # unemployment, sickness
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 32
        assert_state_variable :remaining_years, 18
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a]
      end

      should "show results for male and 35 available years" do
        add_response :male
        add_response Date.parse('8 February 1960')
        add_response 24
        add_response 1 # unemployment, sickness
        add_response 'yes' # child benefit
        add_response 1 # years of benefit
        add_response 1 # years or caring
        add_response 1 # carer's allowance
        assert_current_node :amount_result
        assert_state_variable :qualifying_years_total, 31
        assert_state_variable :remaining_years, 11
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :too_few_qy_enough_remaining_years_a]
      end

      should "show 67 years state_pension_age" do
        add_response :male
        add_response Date.parse('23 March 1969')
        add_response 0
        add_response 0 # unemployment, sickness
        add_response 'yes' # child benefit
        add_response 14 # years of benefit
        add_response 3 # years or caring
        add_response 3 # carer's allowance
        assert_current_node :amount_result
        assert_state_variable :state_pension_age, "67 years"
      end
    end # end timecop 30-04-2014

    context "setup a date before 2016" do
      setup do
        Timecop.travel('2013-07-05')
      end
      should "show results for before April 2016 with enough years" do
        add_response :male
        add_response Date.parse('1 Jan 1950')
        add_response 29
        add_response 0
        add_response 'no'
        add_response 0
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years, :automatic_years_phrase]
      end
    end

    context "show correct phrases for woman with RRE and lived abroad" do
      setup do
        add_response :female
        add_response Date.parse('4 April 1955')
        add_response :yes # Reduced Rate Electiion
        add_response 0 # years of NI
        add_response 0 # Years of unemployment
        add_response :no # claimed benefit
        add_response 0 # years worked between 16 and 19
        add_response :yes # lived or worked abroad
      end
      should "go to outcome and show correct phrases" do
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :less_than_ten, :reduced_rate_election, :lived_or_worked_overseas, :too_few_qy_enough_remaining_years_a]
      end
    end

    context "Woman born between 1953-04-06 and 1961-04-05, with NI qualifying years between 10 and 29" do
      setup do
        Timecop.travel('2014-05-06')
      end

      should "include rre entitlements phrase" do
        add_response :female
        add_response Date.parse("8th February 1958")
        add_response :yes # reduced rate election
        add_response 15 # ni years
        add_response 0 # jsa years
        add_response :no # claimed benefit
        add_response 0 # years worked between 16 and 19
        assert_current_node :amount_result
        assert_phrase_list :result_text, [:too_few_qy_enough_remaining_years_a_intro, :ten_and_greater, :rre_entitlements, :too_few_qy_enough_remaining_years_a]
      end
    end

    context "male and new state pension - should ask lived or worked outside uk" do
      setup do
        add_response :male
        add_response Date.parse('6 April 1951')
        add_response 5
        add_response 0
        add_response :no
        add_response 0
      end
      should "go to amount_result" do
        assert_current_node :lived_or_worked_outside_uk?
      end
    end

    context "Non automatic ni group and born on 29th of February (dynamic date group)" do
      setup do
        add_response :female
        add_response Date.parse('29 February 1960')
        add_response :no
        add_response 0
        add_response 0
        add_response :no
      end
      should "ask if worked abroad" do
        assert_current_node :lived_or_worked_outside_uk?
        assert_state_variable :state_pension_date, Date.parse("01 Mar 2026")
      end
    end
    context "Non automatic ni group (with child benefit) and born on 29th of February (dynami date group)" do
      setup do
        add_response :female
        add_response Date.parse('29 February 1964')
        add_response 0
        add_response 0
        add_response :yes
        add_response 0
        add_response 0
        add_response 0
      end
      should "ask if worked abroad" do
        assert_current_node :lived_or_worked_outside_uk?
        assert_state_variable :state_pension_date, Date.parse("01 Mar 2031")
      end
    end
    context "Check state pension age date if born on 29th of february (static date group)" do
      setup do
        add_response :female
        add_response Date.parse('29 February 1952')
      end
      should "show pension age reached outcome with correct pension age date" do
        assert_current_node :reached_state_pension_age
        assert_state_variable :state_pension_date, Date.parse("06 Jan 2014")
        assert_state_variable :dob, "1952-02-29"
      end
    end
  end #amount calculation
end #ask which calculation
