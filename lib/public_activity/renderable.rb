# frozen_string_literal: true

module PublicActivity
  # Provides logic for rendering activities. Handles both i18n strings
  # support and smart partials rendering (different templates per activity key).
  module Renderable
    # Virtual attribute returning text description of the activity
    # using the activity's key to translate using i18n.
    def text(params = {})
      # TODO: some helper for key transformation for two supported formats
      k = key.split('.')
      k.unshift('activity') if k.first != 'activity'
      k = k.join('.')

      translate_params = parameters.merge(params) || {}	
      I18n.t(k, **translate_params)
    end

    # Renders activity from views.
    #
    # @param [ActionView::Base] context
    # @return [nil] nil
    #
    # Renders activity to the given ActionView context with included
    # AV::Helpers::RenderingHelper (most commonly just ActionView::Base)
    #
    # The *preferred* *way* of rendering activities is
    # to provide a template specifying how the rendering should be happening.
    # However, one may choose using _I18n_ based approach when developing
    # an application that supports plenty of languages.
    #
    # If partial view exists that matches the *key* attribute
    # renders that partial with local variables set to contain both
    # Activity and activity_parameters (hash with indifferent access)
    #
    # Otherwise, it outputs the I18n translation to the context
    # @example Render a list of all activities from a view (erb)
    #   <ul>
    #     <% for activity in PublicActivity::Activity.all %>
    #      <li><%= render_activity(activity) %></li>
    #     <% end %>
    #   </ul>
    #
    # = Layouts
    # You can supply a layout that will be used for activity partials
    # with :layout param.
    # Keep in mind that layouts for partials are also partials.
    # @example Supply a layout
    #   # in views:
    #   #   All examples look for a layout in app/views/layouts/_activity.erb
    #    render_activity @activity, :layout => "activity"
    #    render_activity @activity, :layout => "layouts/activity"
    #    render_activity @activity, :layout => :activity
    #
    #   # app/views/layouts/_activity.erb
    #   <p><%= a.created_at %></p>
    #   <%= yield %>
    #
    # == Custom Layout Location
    # You can customize the layout directory by supplying :layout_root
    # or by using an absolute path.
    #
    # @example Declare custom layout location
    #
    #   # Both examples look for a layout in "app/views/custom/_layout.erb"
    #
    #    render_activity @activity, :layout_root => "custom"
    #    render_activity @activity, :layout      => "/custom/layout"
    #
    # = Creating a template
    # To use templates for formatting how the activity should render,
    # create a template based on activity key, for example:
    #
    # Given a key _activity.article.create_, create directory tree
    # _app/views/public_activity/article/_ and create the _create_ partial there
    #
    # Note that if a key consists of more than three parts splitted by commas, your
    # directory structure will have to be deeper, for example:
    #   activity.article.comments.destroy => app/views/public_activity/articles/comments/_destroy.html.erb
    #
    # == Custom Directory
    # You can override the default `public_directory` template root with the :root parameter
    #
    # @example Custom template root
    #    # look for templates inside of /app/views/custom instead of /app/views/public_directory
    #    render_activity @activity, :root => "custom"
    #
    # == Variables in templates
    # From within a template there are two variables at your disposal:
    # * activity (aliased as *a* for a shortcut)
    # * params   (aliased as *p*) [converted into a HashWithIndifferentAccess]
    #
    # @example Template for key: _activity.article.create_ (erb)
    #   <p>
    #     Article <strong><%= p[:name] %></strong>
    #     was written by <em><%= p["author"] %></em>
    #     <%= distance_of_time_in_words_to_now(a.created_at) %>
    #   </p>
    def render(context, params = {})
      partial_root  = params.delete(:root)         || 'public_activity'
      partial_path  = nil
      layout_root   = params.delete(:layout_root)  || 'layouts'

      if params.has_key? :display
        if params[:display].to_sym == :"i18n"
          text = self.text(params)
          return context.render :text => text, :plain => text
        else
          partial_path = File.join(partial_root, params[:display].to_s)
        end
      end

      context.render(
        params.merge({
          :partial => prepare_partial(partial_root, partial_path),
          :layout  => prepare_layout(layout_root, params.delete(:layout)),
          :locals  => prepare_locals(params)
        })
      )
    end

    def prepare_partial(root, path)
      path || self.template_path(self.key, root)
    end

    def prepare_locals(params)
      locals = params.delete(:locals) || Hash.new

      controller  = PublicActivity.get_controller
      prepared_params = prepare_parameters(params)
      locals.merge(
        {
          :a              => self,
          :activity       => self,
          :controller     => controller,
          :current_user   => controller.respond_to?(:current_user) ? controller.current_user : nil,
          :p              => prepared_params,
          :params         => prepared_params
        }
      )
    end

    def prepare_layout(root, layout)
      if layout
        path = layout.to_s
        unless path.starts_with?(root) || path.starts_with?("/")
          return File.join(root, path)
        end
      end
      layout
    end

    def prepare_parameters(params)
      @prepared_params ||= self.parameters.with_indifferent_access.merge(params)
    end

    protected

    # Builds the path to template based on activity key
    def template_path(key, partial_root)
      path = key.split(".")
      path.delete_at(0) if path[0] == "activity"
      path.unshift partial_root
      path.join("/")
    end
  end
end
