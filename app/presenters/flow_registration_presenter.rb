class FlowRegistrationPresenter
  def initialize(flow)
    @flow = flow
  end

  def slug
    @flow.name
  end

  def need_id
    @flow.need_id
  end

  def start_page_content_id
    @flow.start_page_content_id
  end

  def flow_content_id
    @flow.flow_content_id
  end

  def title
    start_node.title
  end

  def description
    start_node.meta_description
  end

  def external_related_links
    @flow.external_related_links || []
  end

  def start_page_body
    start_node.body
  end

  def start_page_post_body
    start_node.post_body
  end

  def start_page_button_text
    start_node.start_button_text
  end

  module MethodMissingHelper
    OVERRIDES = {
      'calculator.services_payment_partial_name' => 'pay_by_cash_only',
      'calculator.holiday_entitlement_days' => 10,
      'calculator.path_to_outcome' => %w(italy opposite_sex),
      'calculator.ceremony_country' => 'italy'
    }

    def method_missing(method, *_args, &_block)
      object = MethodMissingObject.new(method, nil, true, OVERRIDES)
      OVERRIDES.fetch(object.description) { object }
    end
  end

  def indexable_content
    HTMLEntities.new.decode(
      @flow.nodes.inject([start_node.body]) { |acc, node|
        case node
        when SmartAnswer::Question::Base
          pres = QuestionPresenter.new(node, nil, helpers: [MethodMissingHelper])
          acc.concat([:title, :body, :hint].map { |method|
            pres.send(method)
          })
        when SmartAnswer::Outcome
          pres = OutcomePresenter.new(node, nil, helpers: [MethodMissingHelper])
          acc.concat([:title, :body].map { |method|
            pres.send(method)
          })
        end
      }.compact.join(" ").gsub(/(?:<[^>]+>|\s)+/, " ")
    )
  end

  def state
    'live'
  end

private

  def start_node
    node = SmartAnswer::Node.new(@flow, @flow.name.underscore.to_sym)
    StartNodePresenter.new(node)
  end
end
