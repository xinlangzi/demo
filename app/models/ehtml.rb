class Ehtml < ApplicationRecord

  belongs_to :ehtmlable, :polymorphic => true


  def self.build(html, master)
    master.ehtmls.destroy_all
    master.ehtmls.create(html: html)
  end

  def once
    html if destroy
  end
end