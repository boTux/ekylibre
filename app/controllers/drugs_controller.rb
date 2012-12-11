# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class DrugsController < AdminController
  manage_restfully

  list() do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:unit, :url=>true
    t.column :name, :through=>:nature, :url=>true
    t.column :frequency
    t.column :quantity
    t.column :comment
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  list(:animal_cares, :conditions=>{:drug_id=>['session[:current_drug_id]']}, :order=>"start_on ASC") do |t|
    t.column :name
    t.column :name, :through=>:animal, :url=>true
    t.column :start_on
    t.column :comment
  end

  # Show a list of animals natures
  def index
  end

  # Show one care with params_id
  def show
    return unless @drug = find_and_check(:drug)
    session[:current_drug_id] = @drug.id
    t3e @drug
  end

end