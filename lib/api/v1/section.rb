#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Api::V1::Section
  include Api::V1::Json

  def section_json(section, user, session, includes)
    res = section.as_json(:include_root => false,
                          :only => %w(id name course_id nonxlist_course_id start_at end_at))
    res['sis_section_id'] = section.sis_source_id
    if includes.include?('students')
      proxy = section.enrollments
      if user_json_is_admin?
        proxy = proxy.includes(:user => :pseudonyms)
      else
        proxy = proxy.includes(:user)
      end
      res['students'] = proxy.where(:type => 'StudentEnrollment').
        map { |e| user_json(e.user, user, session, includes) }
    end
    res
  end
end
