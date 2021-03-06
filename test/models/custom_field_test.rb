# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: custom_fields
#
#  active          :boolean          default(TRUE), not null
#  column_name     :string(255)      not null
#  created_at      :datetime         not null
#  creator_id      :integer
#  customized_type :string(255)      not null
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  maximal_length  :integer
#  maximal_value   :decimal(19, 4)
#  minimal_length  :integer
#  minimal_value   :decimal(19, 4)
#  name            :string(255)      not null
#  nature          :string(20)       not null
#  position        :integer
#  required        :boolean          not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#


require 'test_helper'

class CustomFieldTest < ActiveSupport::TestCase
  test_fixtures

  STATIC_VALUES = {
    text: "Lorem ipsum",
    decimal:  3.14159,
    boolean: true,
    date: Date.civil(1953, 3, 16),
    datetime: Time.new(1953, 3, 16, 12, 23)
  }.stringify_keys.freeze


  Ekylibre::Record::Base.descendants.each do |model|
    test "manage custom field on #{model.name.underscore}" do
      I18n.locale = ENV["LOCALE"]
      if !CustomField.customized_type.values.include?(model.name)
        assert_raise ActiveRecord::RecordInvalid, "Cannot add custom field on not customizable models like #{model.name}" do
          CustomField.create!(name: "たてがみ", nature: :text, customized_type: model.name)
        end
      else
        CustomField.nature.values.each do |nature|
          field = CustomField.create!(name: "#{nature.capitalize} info", nature: nature, customized_type: model.name)
          assert model.connection.columns(model.table_name).detect{|c| c.name.to_s == field.column_name}

          field.name = "#{nature.capitalize} インフォ"
          field.save!
          assert model.connection.columns(model.table_name).detect{|c| c.name.to_s == field.column_name}

          if field.choice?
            5.times do |index|
              field.choices.create!(name: "Marvelous ##{index}")
            end
          end

          record = model.first
          assert record.present?, "A #{model.name} record  must exist to test custom field on it"

          method_name = "#{field.column_name}="
          if STATIC_VALUES.has_key?(field.nature)
            record.send(method_name, STATIC_VALUES[field.nature])
          elsif field.choice?
            choice = field.choices.sample
            record.send(method_name, choice.value)
          else
            raise "Unknown custom field datatype: #{field.nature.inspect}"
          end

          record.save!
          record.reload
          value = record.send(field.column_name)
          assert value.present?, "A value must be present in custom field #{field.column_name} after update"

          if STATIC_VALUES.has_key?(field.nature)
            assert_equal STATIC_VALUES[field.nature], value, "Recorded value in custom field #{field.column_name} differs from expected"
          elsif field.choice?
            assert_equal choice.value, value, "Selected choice in custom field #{field.column_name} differs from expected"
          else
            raise "Unknown custom field datatype: #{field.nature.inspect}"
          end

          column_name = field.column_name
          field.destroy!
          assert !model.connection.columns(model.table_name).detect{|c| c.name.to_s == column_name}
          assert !model.connection.columns(model.table_name).detect{|c| c.name.to_s =~ /^\_/}
        end
      end
    end
  end

end
