# frozen_string_literal: true

RecordingStudioSitemaps::Engine.routes.draw do
  post "rebuild", to: "rebuilds#create", as: :rebuild
end
