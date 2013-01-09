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
# == Table: animal_events
#
#  animal_group_id :integer          
#  animal_id       :integer          
#  comment         :text             
#  created_at      :datetime         not null
#  creator_id      :integer          
#  description     :text             
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  moved_at        :datetime         
#  name            :string(255)      not null
#  nature_id       :integer          not null
#  parent_id       :integer          
#  planned_at      :datetime         
#  started_at      :datetime         
#  stopped_at      :datetime         
#  updated_at      :datetime         not null
#  updater_id      :integer          
#  watcher_id      :integer          
#


class AnimalEvent < CompanyRecord
  belongs_to :nature, :class_name => "AnimalEventNature"
  belongs_to :animal, :class_name => "Animal", :conditions => ["is_external = ? AND (outgone_on IS NULL or outgone_on > ?)", false, Time.now]
  belongs_to :animal_group, :class_name => "AnimalGroup"
  belongs_to :parent, :class_name => "AnimalEvent"
  has_many :treatments , :class_name => "AnimalTreatment", :foreign_key => :event_id
  belongs_to :watcher, :class_name => "Entity"
  has_many :diagnostics,:class_name => "AnimalDiagnostic", :foreign_key => :event_id
  has_many :diseases, :through => :diagnostics
  has_many :drugs, :through => :treatments
  has_many :prescriptions, :through => :treatments
  # No columns for this
  # belongs_to :quantity_unit, :class_name => "Unit"
  accepts_nested_attributes_for :treatments,    :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :diagnostics,    :reject_if => :all_blank, :allow_destroy => true
  accepts_nested_attributes_for :diseases,    :reject_if => :all_blank, :allow_destroy => true

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name, :nature
  #]VALIDATORS]

  default_scope order(:started_at, :name)
end