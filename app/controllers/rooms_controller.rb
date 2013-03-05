class RoomsController < ApplicationController
  def show
    @room = params[:id]
  end
end