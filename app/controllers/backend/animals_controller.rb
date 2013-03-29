# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::AnimalsController < BackendController
  manage_restfully :t3e => {:nature_name => "@animal.nature_name"}

  respond_to :pdf, :xml, :json, :html

  unroll_all

  list do |t|
    t.column :work_number, :url => true
    t.column :name, :url => true
    t.column :born_at
    t.column :sex
    t.column :name, :through => :mother, :url => true
    t.column :name, :through => :father, :url => true
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of animal groups

  def index
    @animal = Animal.all
    #parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    #respond with associated models to simplify quering in Ireport
    respond_with @animal, :include => [:father, :mother, :variety, :nature]
  end

   # Liste des enfants de l'animal considéré
  list(:children, :model => :animals, :conditions => [" mother_id = ? OR father_id = ? ",['session[:current_animal_id]'],['session[:current_animal_id]']], :order => "born_at DESC") do |t|
    t.column :name, :url => true
    t.column :born_at
    t.column :sex
    t.column :description
  end

  # Liste des lieux de l'animal considéré
  list(:place, :model => :product_localizations, :conditions => [" product_id = ? ",['session[:current_animal_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through => :container, :url => true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Liste des groupes de l'animal considéré
  list(:group, :model => :product_memberships, :conditions => [" member_id = ? ",['session[:current_animal_id]']], :order => "started_at DESC") do |t|
    t.column :name, :through =>:group, :url => true
    t.column :started_at
    t.column :stopped_at
  end

  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    respond_to do |format|
      format.html do
        session[:current_animal_id] = @animal.id
        t3e @animal, :nature_name => @animal.nature_name
      end
      format.xml {render xml: @animal, :include => [:father, :mother, :nature, :variety, :indicators,
                                                    {:memberships => {:group => nil}},
                                                    {:product_localizations => {:container => nil}}
                                                   ]}
      format.pdf {respond_with @animal, :include => [:father, :mother, :nature, :variety, :indicators,
                                                     {:memberships => {:group => nil}},
                                                     {:product_localizations => {:container => nil}}
                                                    ]}
    end
  end

  def picture
    return unless @animal = find_and_check
    send_file @animal.picture.path(params[:style] || :original)
  end

end