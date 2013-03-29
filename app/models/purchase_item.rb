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
# == Table: purchase_items
#
#  account_id      :integer          not null
#  amount          :decimal(19, 4)   default(0.0), not null
#  annotation      :text
#  created_at      :datetime         not null
#  creator_id      :integer
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  position        :integer
#  pretax_amount   :decimal(19, 4)   default(0.0), not null
#  price_id        :integer          not null
#  product_id      :integer          not null
#  purchase_id     :integer          not null
#  quantity        :decimal(19, 4)   default(1.0), not null
#  tracking_id     :integer
#  tracking_serial :string(255)
#  unit_id         :integer          not null
#  updated_at      :datetime         not null
#  updater_id      :integer
#  warehouse_id    :integer
#


class PurchaseItem < Ekylibre::Record::Base
  acts_as_list :scope => :purchase
  attr_accessible :annotation, :price_id, :product_id, :quantity, :tracking_serial, :unit_id, :purchase_id
  belongs_to :account
  belongs_to :purchase
  belongs_to :price, :class_name => "ProductNaturePrice"
  belongs_to :product
  belongs_to :unit
  belongs_to :warehouse
  has_many :delivery_items, :class_name => "IncomingDeliveryItem", :foreign_key => :purchase_item_id

  accepts_nested_attributes_for :price
  delegate :purchased?, :draft?, :order?, :to => :purchase
  delegate :currency, :to => :price

  acts_as_stockable :mode => :virtual, :direction => :in, :if => :purchased?
  sums :purchase, :items, :pretax_amount, :amount

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :amount, :pretax_amount, :quantity, :allow_nil => true
  validates_length_of :tracking_serial, :allow_nil => true, :maximum => 255
  validates_presence_of :account, :amount, :pretax_amount, :price, :product, :purchase, :quantity, :unit
  #]VALIDATORS]
  validates_presence_of :pretax_amount, :price
  validates_uniqueness_of :tracking_serial, :scope => :price_id, :allow_nil => true, :if => Proc.new{|pl| !pl.tracking_serial.blank? }


  before_validation do
    check_reservoir = true
    self.warehouse_id = Warehouse.first.id if Warehouse.count == 1
    if self.price
      product_nature = self.price.product_nature
      if product_nature.charge_account.nil?
        product_nature.charge_account = Account.find_in_chart(:charges)
        product_nature.save!
      end
      self.account_id = product_nature.charge_account_id
      self.unit_id ||= self.price.product_nature.unit_id
      # self.product_id = self.price.product_nature_id
      self.pretax_amount = (self.price.pretax_amount*self.quantity).round(2)
      self.amount = (self.price.amount*self.quantity).round(2)
    end
    # @TODO : to change dixit Burisu
    #if self.warehouse
    # if self.warehouse.reservoir && self.warehouse.product_id != self.product_id
    #    check_reservoir = false
    #    errors.add(:warehouse_id, :warehouse_can_not_receive_product, :warehouse => self.warehouse.name, :product => self.product.name, :contained_product => self.warehouse.product.name)
    #  end
    #end

    self.tracking_serial = self.tracking_serial.to_s.strip
    unless self.tracking_serial.blank?
      producer = self.purchase.supplier
      unless producer.has_another_tracking?(self.tracking_serial, self.product_id)
        tracking = Tracking.find_by_serial_and_producer_id(self.tracking_serial.upper, producer.id)
        tracking = Tracking.create!(:name => self.tracking_serial, :product_id => self.product_id, :producer_id => producer.id) if tracking.nil?
        self.tracking_id = tracking.id
      end
      self.tracking_serial.upper!
    end

    check_reservoir
  end

  validate do
    # Validate that tracking serial is not used for a different product
    producer = self.purchase.supplier
    unless self.tracking_serial.blank?
      errors.add(:tracking_serial, :serial_already_used_with_an_other_product) if producer.has_another_tracking?(self.tracking_serial, self.product_id)
    end
    if self.price and self.purchase
      errors.add(:price_id, :invalid) if self.price.currency != self.purchase.currency
    end
  end

  def name
    options = {:product => self.product.name, :unit => self.unit.name, :quantity => quantity.to_s, :amount => self.price.amount, :currency => self.price.currency.name}
    if self.tracking
      options[:tracking] = self.tracking.name
      tc(:name_with_tracking, options)
    else
      tc(:name, options)
    end
  end

  def product_name
    self.product.name
  end

  def taxes_amount
    self.amount - self.pretax_amount
  end

  def designation
    d  = self.product_name
    d += "\n"+self.annotation.to_s unless self.annotation.blank?
    d += "\n"+tc(:tracking, :serial => self.tracking.serial.to_s) if self.tracking
    d
  end

  def undelivered_quantity
    return self.quantity-self.delivery_items.sum(:quantity)
  end

  def label
    self.product.name
  end

end