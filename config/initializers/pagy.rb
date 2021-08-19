# frozen_string_literal: true

require 'pagy'
require 'pagy/extras/overflow'

Pagy::VARS[:overflow] = :last_page
