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
# == Table: issues
#
#  created_at           :datetime         not null
#  creator_id           :integer
#  description          :text
#  geolocation          :spatial({:srid=>
#  gravity              :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string(255)      not null
#  nature               :string(255)      not null
#  observed_at          :datetime         not null
#  picture_content_type :string(255)
#  picture_file_name    :string(255)
#  picture_file_size    :integer
#  picture_updated_at   :datetime
#  priority             :integer
#  state                :string(255)
#  target_id            :integer          not null
#  target_type          :string(255)      not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#


class Issue < Ekylibre::Record::Base
  include Versionable
  enumerize :nature, in: Nomen::IssueNatures.all, default: Nomen::IssueNatures.default, predicates: {prefix: true}
  has_many :interventions
  belongs_to :target , polymorphic: true

  has_picture

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :observed_at, :picture_updated_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :gravity, :picture_file_size, :priority, allow_nil: true, only_integer: true
  validates_length_of :name, :nature, :picture_content_type, :picture_file_name, :state, :target_type, allow_nil: true, maximum: 255
  validates_presence_of :name, :nature, :observed_at, :target, :target_type
  #]VALIDATORS]
  validates_inclusion_of :priority, in: 0..5
  validates_attachment_content_type :picture, content_type: /image/

  delegate :name, to: :target, prefix: true

  state_machine :state, :initial => :opened do

    ## define states
    state :opened
    state :closed
    state :aborted

    ## define events

    # # way A1
    # event :treat do
    #   transition :opened => :in_progress, if: :has_intervention?
    # end

    # way A2
    event :close do
      # transition :in_progress => :closed, if: :has_intervention?
      transition :opened => :closed # , if: :has_intervention?
    end

    # way B1
    event :abort do
      transition :opened => :aborted
      # transition :in_progress => :aborted
    end

    # way A3 || B2
    event :reopen do
      transition :closed => :opened
      transition :aborted => :opened
    end

    ## define callbacks after and before transition

  end

  before_validation do
    if self.target
      self.target_type = self.target.class.name
    end
    if self.nature
      self.name = (self.target ? tc(:name_with_target, nature: self.nature.l, target: target.name) : tc(:name_without_target, nature: self.nature.l))
    end
  end

  protect(on: :destroy) do
    self.has_intervention?
  end

  def has_intervention?
    self.interventions.any?
  end

  def status
    if self.opened?
      return (has_intervention? ? :caution : :stop)
    else
      return :go
    end
  end

  def picture_path(style=:original)
    self.picture.path(style)
  end

  def interventions_count
    self.interventions.count
  end

  def geolocation=(value)
    if value.is_a?(String) and value =~ /\A\{.*\}\z/
      value = Charta::Geometry.new(JSON.parse(value).to_json, :WGS84).to_rgeo
    elsif !value.blank?
      value = Charta::Geometry.new(value).to_rgeo
    end
    self["geolocation"] = value
  end

end
