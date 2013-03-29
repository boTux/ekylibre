# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: activity_watchings
#
#  activity_id       :integer          not null
#  area_unit_id      :integer
#  created_at        :datetime         not null
#  creator_id        :integer
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  position          :integer
#  product_nature_id :integer          not null
#  updated_at        :datetime         not null
#  updater_id        :integer
#  work_unit_id      :integer
#
class ActivityWatching < Ekylibre::Record::Base
  attr_accessible :activity_id, :product_nature_id, :area_unit_id, :work_unit_id
  belongs_to :activity
  belongs_to :area_unit, :class_name => "Unit"
  belongs_to :product_nature
  belongs_to :work_unit, :class_name => "Unit"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_presence_of :activity, :product_nature
  #]VALIDATORS]
end