#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class GanttsController < ApplicationController
  menu_item :gantt
  before_filter :find_optional_project

  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  include QueriesHelper
  include SortHelper
  include Redmine::Export::PDF

  def show
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    retrieve_query
    @query.group_by = nil
    @gantt.query = @query if @query.valid?

    basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'

    respond_to do |format|
      format.html { render :action => "show", :layout => !request.xhr? }
      format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
      format.pdf  { send_data(@gantt.to_pdf, :type => 'application/pdf', :filename => "#{basename}.pdf") }
    end
  end

  def update
    show
  end

  def edit_gantt
    date_from = Date.parse(params[:date_from])
    date_to = Date.parse(params[:date_to])
    months = date_to.month - date_from.month + 1
    params[:year] = date_from.year
    params[:month] = date_from.month
    params[:months] = months
    @gantt = Redmine::Helpers::Gantt.new(params)
    @gantt.project = @project
    text, status = @gantt.edit(params)
    render :text=>text, :status=>status
  end

  def find_optional_project
    begin
      if params[:action] && params[:action].to_s == "edit_gantt"
        @project = Project.find(params[:project_id]) unless params[:project_id].blank?
        allowed = User.current.allowed_to?(:edit_issues, @project, :global => true)
        if allowed
          return true
        else
          render :text => l(:text_edit_gantt_lack_of_permission), :status=>403
        end
      else
        super
      end
    rescue => e
      return e.to_s + "\n===\n" + [$!,$@.join("\n")].join("\n")
    end
  end
end
