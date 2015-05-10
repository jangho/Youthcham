class NoticeController < ApplicationController
  before_action :authenticate_user!, only: [:write]

  def index
    @notices = Notice.all.reverse
  end

  def write
  end

  def view
  end
end
