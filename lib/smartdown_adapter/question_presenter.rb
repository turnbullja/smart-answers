module SmartdownAdapter
  class QuestionPresenter
    extend Forwardable

    def_delegators :@smartdown_question, :title, :hint, :options

    def initialize(smartdown_question, smartdown_answer)
      @smartdown_question = smartdown_question
      @smartdown_answer = smartdown_answer
    end

    def body
      @smartdown_question.body && markdown_to_html(smartdown_question.body.strip)
    end

    def post_body
      @smartdown_question.post_body && markdown_to_html(smartdown_question.post_body.strip)
    end

    def has_body?
      body.present?
    end

    def has_hint?
      hint.present?
    end

    def has_post_body?
      post_body.present?
    end

    def error
      @smartdown_answer.error if @smartdown_answer
    end

    def partial_template_name
      case smartdown_question
      when Smartdown::Api::MultipleChoice
        "multiple_choice_question"
      when Smartdown::Api::DateQuestion
        "date_question"
      when Smartdown::Api::CountryQuestion
        "country_question"
      when Smartdown::Api::SalaryQuestion
        "salary_question"
      when Smartdown::Api::TextQuestion
        "text_question"
      when Smartdown::Api::PostcodeQuestion
        "postcode_question"
      end
    end

  private

    attr_reader :smartdown_question

    def markdown_to_html markdown
      Govspeak::Document.new(markdown).to_html.html_safe
    end

  end
end
