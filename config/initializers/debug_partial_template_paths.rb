unless ENV["DISABLE_DEBUG_PARTIAL_TEMPLATE_PATHS"]
  wrapper = PartialTemplateWrapper.new
  partial_renderer = PartialTemplateRenderInterceptor[wrapper]
  ActionView::PartialRenderer.prepend(partial_renderer)
end
