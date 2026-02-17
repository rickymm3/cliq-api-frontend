module PostsHelper
  VARIANT_ERRORS = [
    LoadError,
    NameError,
    RuntimeError, # some processors raise generic runtime errors
    ActiveStorage::Error
  ].freeze

  def safe_variant(image, transformations)
    return image unless image.respond_to?(:variable?) && image.variable?

    image.variant(**transformations).processed
  rescue *VARIANT_ERRORS => e
    Rails.logger.warn("[posts] Falling back to original attachment for variant: #{e.class} #{e.message}")
    image
  end
end
