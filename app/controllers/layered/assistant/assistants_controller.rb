module Layered
  module Assistant
    # Assistants point at a model, a persona and a set of skills, all of
    # which are owner-scoped. The resource class cannot scope them itself -
    # a field's `collection:` is resolved without a controller - so the
    # options are filled in here, and the ids that come back are resolved
    # through `scoped` before they reach the record.
    #
    # `@fields` is set by the gem's own `load_layered_resource`, declared
    # when `Layered::Resource::Controller` is included by ResourcesController,
    # so it has always run by the time this subclass's callback does.
    class AssistantsController < ResourcesController
      before_action :scope_choice_fields, only: [ :new, :create, :edit, :update ]

      private

      def scope_choice_fields
        models = scoped_models.map { |model| [ "#{model.provider.name} - #{model.name}", model.id ] }
        personas = scoped(Persona).by_name.map { |persona| [ persona.name, persona.id ] }
        skills = scoped(Skill).by_name.map { |skill| [ skill.name, skill.id ] }

        @fields = @fields.map do |field|
          case field[:attribute]
          when :default_model_id then field.merge(collection: models)
          when :persona_id then field.merge(collection: personas)
          when :skill_ids then field.merge(collection: skills)
          else field
          end
        end
      end

      # An out-of-scope model or persona 404s rather than being silently
      # dropped, matching how a record itself is looked up. Skills are
      # filtered instead: the picker posts a list, and one stale entry
      # should not fail the whole save.
      def layered_resource_params
        attributes = super

        if attributes[:default_model_id].present?
          attributes[:default_model_id] = scoped_models.find(attributes[:default_model_id]).id
        end

        if attributes[:persona_id].present?
          attributes[:persona_id] = scoped(Persona).find(attributes[:persona_id]).id
        end

        if attributes.key?(:skill_ids)
          attributes[:skill_ids] = scoped(Skill).where(id: Array(attributes[:skill_ids]).compact_blank).ids
        end

        attributes
      end
    end
  end
end
