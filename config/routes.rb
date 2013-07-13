CanvasRails::Application.routes.draw do
  resources :submission_comments, :only => :destroy

  delete 'inbox' => 'context#mark_inbox_as_read', :as => :mark_inbox_as_read
  match 'inbox' => 'context#inbox', :as => :inbox
  delete 'inbox/:id' => 'context#destroy_inbox_item', :as => :destroy_inbox_item
  match 'inbox/:id' => 'context#inbox_item', :as => :inbox_item

  match 'conversations/discussion_replies' => 'context#discussion_replies', :as => :discussion_replies
  match 'conversations/unread' => 'conversations#index', :redirect_scope => 'unread', :as => :conversations_unread
  match 'conversations/starred' => 'conversations#index', :redirect_scope => 'starred', :as => :conversations_starred
  match 'conversations/sent' => 'conversations#index', :redirect_scope => 'sent', :as => :conversations_sent
  match 'conversations/archived' => 'conversations#index', :redirect_scope => 'archived', :as => :conversations_archived
  match 'conversations/find_recipients' => 'search#recipients', :as => :connect # use search_recipients_url instead
  match 'search/recipients' => 'search#recipients', :as => :search_recipients
  post 'conversations/mark_all_as_read' => 'conversations#mark_all_as_read', :as => :conversations_mark_all_as_read
  post 'conversations/watched_intro' => 'conversations#watched_intro', :as => :conversations_watched_intro
  match 'conversations/batches' => 'conversations#batches', :as => :conversation_batches
  resources :conversations, :only => [:index, :show, :update, :create, :destroy] do
    post 'add_recipients', :on => :collection, :as => :add_recipients
    post 'add_message', :on => :collection, :as => :add_message
    post 'remove_messages', :on => :collection, :as => :remove_messages
  end

  ## So, this will look like:
  ## http://instructure.com/register/5R32s9iqwLK75Jbbj0
  match 'register/:nonce',
    :controller => 'communication_channels', :action => 'confirm', :as => :registration_confirmation
  # deprecated
  match 'pseudonyms/:id/register/:nonce',
    :controller => 'communication_channels', :action => 'confirm', :as => :registration_confirmation_deprecated
  match 'confirmations/:user_id/re_send/:id',
    :controller => 'communication_channels', :action => 're_send_confirmation', :id => nil, :as => :re_send_confirmation
  match "forgot_password",
    :controller => 'pseudonyms', :action => 'forgot_password', :as => :forgot_password
  get "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'confirm_change_password', :as => :confirm_change_password
  post "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'change_password', :conditions => {:method => :post}, :as => :change_password

  # callback urls for oauth authorization processes
  match "oauth", :controller => "users", :action => "oauth", :as => :change_password
  match "oauth_success", :controller => "users", :action => "oauth_success", :as => :oauth_success

  match "mr/:id", :controller => 'info', :action => 'message_redirect', :as => :message_redirect
  match 'help_links', :controller => 'info', :action => 'help_links', :as => :help_links


  def add_question_banks(context)
    resources :question_banks do
      match 'bookmark', :on => :member, :as => :bookmark
      match 'reorder', :on => :member, :as => :reorder
      match 'questions', :on => :member, :as => :questions
      match 'move_questions', :on => :member, :as => :move_questions
      resources :assessment_questions do
        match 'move', :on => :member, :as => :move
      end
    end
  end

  def add_groups(context)
    resources :groups
    resources :group_categories, :only => [:create, :update, :destroy]
    get 'group_unassigned_members', :controller => 'groups', :action => 'unassigned_members', :as => :group_unassigned_members
    post 'group_assign_unassigned_members', :controller => 'groups', :action => 'assign_unassigned_members', :as => :group_assign_unassigned_members
  end

  def add_files(context, options={})
    resources :files, :collection => {:quota => :get, :reorder => :post} do 
      match 'inline',  :action => 'text_show', :as => :text_inline
      match 'download', :action => 'show', :download => '1', :as => :download
      match 'download.:type', :action => 'show', :download => '1'
      match 'preview', :action => 'show', :preview => '1', :as => :preview
      match 'inline_view', :action => 'show', :inline => '1', :as => :inline_view
      match 'contents', :action => 'attachment_content', :as => :attachment_content
      match ":file_path", :file_path => /.+/, :action => 'show_relative', :as => :relative_path
    end
    match 'images', :controller => 'files', :action => 'images', :as => :images  if options[:images]
    match "file_contents/:file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative', :as => :relative_file_path if options[:folders]
    if options[:folders]
      resources :folders do
        match 'download', :on => :member
      end
    end
  end

  def add_media(context)
    match 'media_download', :controller => 'users', :action => 'media_download', :as => :media_download
    match 'media_download.:type', :controller => 'users', :action => 'media_download', :as => :typed_media_download
  end

  def add_users(context)
    match 'users', :action => 'roster'
    match 'user_services', :action => 'roster_user_services'
    match 'users/:user_id/usage', :action => 'roster_user_usage'
    yield if block_given?
    get 'users/:id', :action => 'roster_user'
  end

  def add_chat(context)
    resources :chats
    match 'chat'
    match 'tinychat.html', :action => 'chat_iframe'
  end

  def add_announcements(context)
    resources :announcements do
      post 'external_feeds', :on => :collection, :action => 'create_external_feed'
      delete 'external_feeds/:id', :on => :collection, :action => 'destroy_external_feed'
    end
  end

  def add_discussions(context)
    resources :discussion_topics, :only => [:index, :new, :show, :edit, :destroy] do
      match ':extras', :action => :show, :on => :member
    end

    resources :discussion_entries
  end

  def add_wiki(context)
    ####
    ## Leaving these routes here for when we need them later :)
    ##
    ## Aside from the /wiki route itself, all new routes will be /pages. The /wiki route will be reused to redirect
    ## the user to the wiki front page, if configured, or the wiki page list otherwise.
    ####
    # context.wiki 'wiki', :controller => 'wiki_pages', :action => 'front_page', :conditions => { :method => :get }

    ####
    ## Placing these routes above the /wiki routes below will cause the helper functions to generate urls and paths
    ## pointing to /pages rather than the legacy /wiki.
    ####
    # context.resources :wiki_pages, :as => 'pages'
    #   wiki_page.latest_version_number 'revisions/latest', :controller => 'wiki_page_revisions', :action => 'latest_version_number'
    #   wiki_page.resources :wiki_page_revisions, :as => "revisions"
    #   wiki_page.resources :wiki_page_comments, :as => "comments"
    # end
    #
    ####
    ## We'll just do specific routes here until we can swap /pages and /wiki completely.
    ####
    match 'pages', :controller => 'wiki_pages', :action => 'pages_index', :as => :pages

    resources :wiki_pages, :as => 'wiki' do 
      match 'latest', :on => :collection, :controller => 'wiki_page_revisions', :action => 'latest_version_number'
      resources :wiki_page_revisions, :as => "revisions"
      resources :wiki_page_comments, :as => "comments"
    end

    ####
    ## This will cause the helper functions to generate /pages urls, but will still allow /wiki routes to work properly
    ####
    #context.named_wiki_page 'pages/:id', :id => /[^\/]+/, :controller => 'wiki_pages', :action => 'show'

    match 'wiki/:id' => 'wiki_pages#show', :id => /[^\/]+/, :as => :named_wiki_page
  end

  def add_conferences(context)
    resources :conferences do 
      match "join"
      match "close"
      match "settings"
    end
  end

  def add_zip_file_imports(context)
    resources :zip_file_imports, :only => [:new, :create, :show]
    match 'imports/files' => 'content_imports#files'
  end

  ## There are a lot of resources that are all scoped to the course level
  ## (assignments, files, wiki pages, user lists, forums, etc.).  Many of
  ## these resources also apply to groups and individual users.  We call
  ## courses, users, groups, or even accounts in this setting, "contexts".
  ## There are some helper methods like the before_filter :get_context in application_controller
  ## and the application_helper method :context_url to make retrieving
  ## these contexts, and also generating context-specific urls, easier.
  resources :courses do |course|
    ## DEPRECATED
    get 'self_enrollment/:self_enrollment', :action => :self_enrollment, :as => :self_enrollment
    post 'self_unenrollment/:self_unenrollment', :action => :self_unenrollment, :as => :self_unenrollment
    match 'restore', :as => :restore
    match 'backup', :as => :backup
    match 'unconclude', :as => :unconclude
    match 'students', :as => :students
    match 'enrollment_invitation', :as => :enrollment_invitation
    add_users(course) do
      match 'users/prior' => 'context#prior_users', :as => :prior_users
    end
    match 'statistics'
    delete 'unenroll/:id', :action => :unenroll_user
    post 'move_enrollment/:id', :action => :move_enrollment
    match 'limit_user_grading/:id', :action => 'limit_user'
    delete 'conclude_user/:id', :action => 'conclude_user'
    post 'unconclude_user/:id', :action => 'unconclude_user', :as => :unconclude_user_enrollment
    resources :sections, :except => %w(index edit new) do
      match 'crosslist/confirm/:new_course_id', :action => 'crosslist_check'
      post 'crosslist'
      delete 'crosslist', :action => 'uncrosslist'
    end
    match 'undelete', :controller => 'context', :action => 'undelete_index', :as => :undelete_items
    match 'undelete/:asset_string', :controller => 'context', :action => 'undelete_item', :as => :undelete_item
    match 'settings', :as => :settings
    match 'details', :action => 'settings'
    post 're_send_invitations'
    match 'enroll_users'
    match 'link_enrollment'
    match 'update_nav'
    resources :gradebooks do
      collection do
        get 'change_gradebook_version'
        get 'blank_submission'
        get 'speed_grader'
        post 'update_submission'
        get 'history'
      end
      member do
        post 'submissions_upload/:assignment_id', :action => :submissions_zip_upload
      end
    end
    resource :gradebook2
    match 'attendance' => 'gradebooks#attendance', :as => :attendance
    match 'attendance/:user_id' => 'gradebooks#attendance', :as => :attendance_user
    match 'imports' => 'content_imports#intro'
    add_zip_file_imports(course)
    scope 'imports', :as => 'imports' do
      match 'quizzes' => 'content_imports#quizzes'
      match 'content' => 'content_imports#content'
      get 'choose_course' => 'content_imports#choose_course'
      get 'choose_content' => 'content_imports#choose_content'
      get 'copy_course_checklist' => 'content_imports#copy_course_checklist'
      get 'copy_course_finish' => 'content_imports#copy_course_finish'
      get 'migrate' => 'content_imports#migrate_content'
      match 'upload' => 'content_imports#migrate_content_upload'
      match 's3_success' => 'content_imports#migrate_content_s3_success'
      post 'copy' => 'content_imports#copy_course_content'
      match 'migrate/:id' => 'content_imports#migrate_content_choose'
      match 'migrate/:id/execute' => 'content_imports#migrate_content_execute'
      match 'review' => 'content_imports#review'
      match 'list' => 'content_imports#index'
      get ':id' => 'content_imports#copy_course_status'
      get ':id/download_archive' => 'content_imports#download_archive'
   end
   resource :gradebook_upload
   match "grades" => 'gradebooks#grade_summary', :id => nil
   match "grading_rubrics" => 'gradebooks#grading_rubrics'
   match "grades/:id" => 'gradebooks#grade_summary'
   add_announcements(course)
   add_chat(course)
   match 'calendar' => 'calendars#show'
   match 'locks' => 'courses#locks'
   add_discussions(course)
   resources :assignments, :collection => {:syllabus => :get, :submissions => :get}, :member => {:list_google_docs => :get} do 
     resources :submissions do
       post 'turnitin/resubmit', :action => 'resubmit_to_turnitin'
       match 'turnitin/:asset_string', :action => 'turnitin_report'
     end
     match "rubric"
     resource :rubric_association, :as => :rubric do
       resources :rubric_assessments, :as => 'assessments'
     end
     get "peer_reviews"
     post "assign_peer_reviews" 
     delete "peer_reviews/:id", :action => 'delete_peer_review'
     post "peer_reviews/:id", :action => 'remind_peer_review'
     post "peer_reviews/users/:reviewer_id", :action => 'assign_peer_review'
     put "mute", :action => "toggle_mute"
   end
   resources :grading_standards, :only => %w(index create update destroy)
   resources :assignment_groups, :collection => {:reorder => :post} do 
     match 'reorder', :action => 'reorder_assignments'
   end
   match 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch'
   resources :external_tools do
     collection do
       get 'retrieve'
       get 'homework_submissions'
     end
     match 'resource_selection'
     match 'homework_submission'
     match 'finished'
   end
   resources :submissions
   resources :calendar_events
   add_files(course, :relative => true, :images => true, :folders => true)
   add_groups(course)
   add_wiki(course)
   add_conferences(course)
   add_question_banks(course)
   match 'quizzes/publish' => 'quizzes#publish'
   resources :quizzes do
     match "managed_quiz_data"
     match "reorder"
     match "history"
     match "statistics"
     match "read_only"
     match 'filters'
     resources :quiz_submissions, :as => "submissions" do
       put 'backup', :on => :collection
       post 'record_answer', :on => :member
     end
     post 'extensions/:user_id' => 'quiz_submissions#extensions'
     resources :quiz_questions, :as => "questions", :only => %w(create update destroy show)
     resources :quiz_groups, :as => "groups", :only => %w(create update destroy) do 
       match "reorder"
     end
     match 'take', :on => :member, :action => :show, :defaults => { :take => '1' }
     match 'take/questions/:question_id', :action => :show, :on => :member, :defaults => { :take => '1'}


     match "moderate"
     match "lockdown_browser_required"
   end
   match 'quiz_statistics/:quiz_statistics_id/files/:file_id/download' => 'files#show', :download => '1'

   resources :collaborations

   resources :gradebook_uploads
   resources :rubrics
   resources :rubric_associations do 
     match "invite"
     match "remind/:assessment_request_id", :action => "remind"
     resources :rubric_assessments, :as => 'assessments'
   end
   match 'outcomes/users/:user_id' => 'outcomes#user_outcome_results'
   resources :outcomes do
     collection do
       get 'list'
       post 'add_outcome'
     end
     post 'alignments/reorder', :action => 'reorder_alignments'
     get 'alignments/:id', :action => 'alignment_redirect'
     post 'alignments', :action => 'align'
     delete 'alignments/:id', :action => 'remove_alignment'
     match 'results', :action => 'outcome_results'
     match 'results/:id', :action => 'outcome_result'
     match 'details'
   end
   resources :outcome_groups, :only => %w(create update destroy) do 
     match 'reorder'
   end
   resources :context_modules, :as => :modules do
     collection do 
       post 'reorder'
       get 'progressions'
     end
     post 'items', :action => 'add_item'
     post 'reorder', :action => 'reorder_items'
     match 'collapse', :action => 'toggle_collapse'
     match 'prerequisites/:code', :action => 'content_tag_prerequisites_needing_finishing'
     match 'items/last', :action => 'module_redirect', :last => 1
     match 'items/first', :action => 'module_redirect', :first => 1
   end
   resources :content_exports, :only => %w(create index destroy show)
   match 'modules/items/assignment_info' => 'context_modules#content_tag_assignment_data'
   get 'modules/items/:id' => 'context_modules#item_redirect'
   get 'modules/items/sequence/:id' => 'context_modules#item_details'
   delete 'modules/items/:id' => 'context_modules#remove_item'
   put 'modules/items/:id' => 'context_modules#update_item'
   match 'confirm_action'
   get 'copy'
   post 'copy', :action => 'copy_course'
   add_media(course)
   match 'user_notes' => 'user_notes#user_notes'
   match 'switch_role/:role', :action => 'switch_role'
   get 'details/sis_publish', :action => 'sis_publish_status'
   post 'details/sis_publish', :action => 'publish_to_sis'
   resources :user_lists, :only => :create
   post 'reset', :action => 'reset_content'
   resources :alerts
   post 'student_view', :action => 'student_view'
   delete 'student_view', :action => 'leave_student_view'
   delete 'test_student', :action => 'reset_test_student'
   get 'content_migrations' => 'content_migrations#index'
 end

  post '/submissions/:submission_id/attachments/:attachment_id/crocodoc_sessions' => 'crocodoc_sessions#create'
  post '/attachments/:attachment_id/crocodoc_sessions' => 'crocodoc_sessions#create'

  resources :page_views, :only => [:update]
  post 'media_objects' => 'context#create_media_object', :as => :create_media_object
  match 'media_objects/kaltura_notifications' => 'context#kaltura_notifications', :as => :kaltura_notifications
  match 'media_objects/:id' => 'context#media_object_inline', :as => :media_object
  match 'media_objects/:id/redirect' => 'context#media_object_redirect', :as => :media_object_redirect
  match 'media_objects/:id/thumbnail' => 'context#media_object_thumbnail', :as => :media_object_thumbnail
  match 'media_objects/:media_object_id/info' =>  'media_objects#show', :as => :media_object_info

  get "media_objects/:media_object_id/media_tracks/:id" => 'media_tracks#show', :as => :show_media_tracks
  post 'media_objects/:media_object_id/media_tracks' => 'media_tracks#create', :as => :create_media_tracks
  delete "media_objects/:media_object_id/media_tracks/:media_track_id" => 'media_tracks#destroy', :as => :delete_media_tracks

  match 'external_content/success/:service' => 'external_content#success', :as => :external_content_success
  match 'external_content/retrieve/oembed' =>  'external_content#oembed_retrieve', :as => :external_content_oembed_retrieve
  match 'external_content/cancel/:service' =>  'external_content#cancel', :as => :external_content_cancel

  # We offer a bunch of atom and ical feeds for the user to get
  # data out of Instructure.  The :feed_code attribute is keyed
  # off of either a user, and enrollment, a course, etc. based on
  # that item's uuid.  In config/initializers/active_record.rb you'll
  # find a feed_code method to generate the code, and in
  # application_controller there's a get_feed_context to get it back out.
  match "feeds/calendars/:feed_code" => "calendar_events_api#public_feed", :as => :feeds_calendar
  match "feeds/calendars/:feed_code.:format" => "calendar_events_api#public_feed", :as => :feeds_calendar_format
  match "feeds/forums/:feed_code" => "discussion_topics#public_feed", :as => :feeds_forum
  match "feeds/forums/:feed_code.:format" => "discussion_topics#public_feed", :as => :feeds_forum_format
  match "feeds/topics/:discussion_topic_id/:feed_code" => "discussion_entries#public_feed", :as => :feeds_topic
  match "feeds/topics/:discussion_topic_id/:feed_code.:format" => "discussion_entries#public_feed", :as => :feeds_topic_format
  match "feeds/announcements/:feed_code" => "announcements#public_feed", :as => :feeds_announcements
  match "feeds/announcements/:feed_code.:format" => "announcements#public_feed", :as => :feeds_announcements_format
  match "feeds/courses/:feed_code" => "courses#public_feed", :as => :feeds_course
  match "feeds/courses/:feed_code.:format" => "courses#public_feed", :as => :feeds_course_format
  match "feeds/groups/:feed_code" => "groups#public_feed", :as => :feeds_group
  match "feeds/groups/:feed_code.:format" => "groups#public_feed", :as => :feeds_group_format
  match "feeds/enrollments/:feed_code" => "courses#public_feed", :as => :feeds_enrollment
  match "feeds/enrollments/:feed_code.:format" => "courses#public_feed", :as => :feeds_enrollment_format
  match "feeds/users/:feed_code" => "users#public_feed", :as => :feeds_user
  match "feeds/users/:feed_code.:format" => "users#public_feed", :as => :feeds_user_format
  match "feeds/eportfolios/:eportfolio_id.:format" => "eportfolios#public_feed", :as => :feeds_eportfolio
  match "feeds/conversations/:feed_code" => "conversations#public_feed", :as => :feeds_conversation
  match "feeds/conversations/:feed_code.:format" => "conversations#public_feed", :as => :feeds_conversation_format

  resources :assessment_questions do 
    match 'files/:id/download' => 'files#assessment_question_show', :download => '1'
    match 'files/:id/preview' => 'files#assessment_question_show', :preview => '1'
    match 'files/:id/:verifier' => 'files#assessment_question_show', :download => '1'
  end

  resources :eportfolios, :except => [:index]  do 
    match "reorder_categories"
    match ":eportfolio_category_id/reorder_entries"
    resources :categories, :controller => "eportfolio_categories"
    resources :entries, :controller => "eportfolio_entries" do |entry|
      resources :page_comments, :as => "comments", :only => %w(create destroy)
      get "files/:attachment_id", :action => "attachment"
      get "submissions/:submission_id", :action => "submission"
    end
    match "export"
    get ":category_name" => "eportfolio_categories#show"
    get ":category_name/:entry_name" => "eportfolio_entries#show"
  end

  resources :groups do |group|
    add_users(group)
    delete 'remove_user/:id' => 'groups#remove_user'
    match 'add_user'
    get 'accept_invitation/:uuid', :action => 'accept_invitation'
    get 'members', :action => 'context_group_members'
    add_announcements(group)
    add_discussions(group)
    resources :calendar_events
    add_chat(group)
    add_files(group, :images => true, :folders => true)
    add_zip_file_imports(group)
    resources :external_tools, :only => [:show], :collection => {:retrieve => :get}
    add_wiki(group)
    add_conferences(group)
    add_media(group)
    resources :collaborations
    match 'calendar' => 'calendars#show'
  end

  resources :accounts do |account|
    get 'statistics', :on => :member
    match 'settings'
    match 'admin_tools'
    post 'account_users', :action => 'add_account_user'
    delete 'account_users/:id', :action => 'remove_account_user'

    resources :grading_standards, :only => %w(index create update destroy)

    match 'statistics'
    match 'statistics/over_time/:attribute', :action => 'statistics_graph'
    match 'statistics/over_time/:attribute.:format', :action => 'statistics_graph'
    match 'turnitin/:id/:shared_secret', :action => 'turnitin_confirmation'
    resources :permissions, :controller => 'role_overrides', :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    resources :role_overrides, :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    resources :terms
    resources :sub_accounts
    match 'avatars'
    get 'sis_import'
    resources :sis_imports, :controller => 'sis_imports_api', :only => [:create, :show]
    post 'users' => 'users#create'
    match 'users/:user_id/delete', :action => 'confirm_delete_user'
    delete 'users/:user_id', :action => 'remove_user'
    resources :users
    resources :account_notifications, :only => [:create, :destroy]
    add_announcements(account)
    resources :assignments
    resources :submissions
    resources :account_authorization_configs
    put 'account_authorization_configs' => 'account_authorization_configs#update_all'
    delete 'account_authorization_configs' => 'account_authorization_configs#destroy_all'
    match 'test_ldap_connections' => 'account_authorization_configs#test_ldap_connection'
    match 'test_ldap_binds' => 'account_authorization_configs#test_ldap_bind'
    match 'test_ldap_searches' => 'account_authorization_configs#test_ldap_search'
    match 'test_ldap_logins' => 'account_authorization_configs#test_ldap_login'
    match 'saml_testing' => 'account_authorization_configs#saml_testing'
    match 'saml_testing_stop' => 'account_authorization_configs#saml_testing_stop'
    match 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch'
    resources :external_tools do 
      match 'finished'
    end
    add_chat(account)
    match 'outcomes/users/:user_id' => 'outcomes#user_outcome_results'
    resources :outcomes do
      collection do 
        get 'list'
        post 'add_outcome'
      end
      match 'results', :action => 'outcome_results'
      match 'results/:id', :action => 'outcome_result'
      match 'details'
    end
    resources :outcome_groups, :only => %w(create update destroy) do 
      match 'reorder'
    end
    resources :rubrics
    resources :rubric_associations do 
      resources :rubric_assessments, :as => 'assessments'
    end
    add_files(account, :relative => true, :images => true, :folders => true)
    add_media(account)
    add_groups(account)
    resources :outcomes
    match 'courses'
    match 'courses/:id', :action => 'courses_redirect'
    match 'user_notes'
    match 'run_report'
    resources :alerts
    add_question_banks(account)
    resources :user_lists, :only => :create
  end
  get 'images/users/:user_id' => 'users#avatar_image', :as => :avatar_image
  match 'images/thumbnails/:id/:uuid' => 'files#image_thumbnail', :as => :thumbnail_image
  match 'images/thumbnails/show/:id/:uuid' => 'files#show_thumbnail', :as => :show_thumbnail_image
  post 'images/users/:user_id/report' => 'users#report_avatar_image', :as => :report_avatar_image
  put 'images/users/:user_id' => 'users#update_avatar_image', :as => :update_avatar_image

  match 'all_menu_courses' => 'users#all_menu_courses', :as => :all_menu_courses

  match "grades" => "users#grades", :as => :grades

  get "login" => "pseudonym_sessions#new", :as => :login
  post "login" => "pseudonym_sessions#create", :as => :login
  match "logout" => "pseudonym_sessions#destroy", :as => :logout
  get "login/cas" => "pseudonym_sessions#new", :as => :cas_login
  match "login/otp" => "pseudonym_sessions#otp_login", :as => :otp_login
  get "login/:account_authorization_config_id" => "pseudonym_sessions#new", :as => :aac_login
  delete "users/:user_id/mfa" => "pseudonym_sessions#disable_otp_login", :as => :disable_mfa
  match "file_session/clear" => "pseudonym_sessions#clear_file_session", :as => :clear_file_session
  match "register" => "users#new", :as => :register
  match "register_from_website" => "users#new", :as => :register_from_website
  get 'enroll/:self_enrollment_code' => 'self_enrollments#new', :as => :enroll
  post 'enroll/:self_enrollment_code' => 'self_enrollments#create', :as => :enroll_frd
  match 'services' => 'users#services', :as => :services
  match 'search/bookmarks' => 'users#bookmark_search', :as => :bookmark_search
  match 'search/rubrics' => "search#rubrics", :as => :search_rubrics
  delete 'tours/dismiss/:name' => 'tours#dismiss', :as => :dismiss_tour
  delete 'tours/dismiss/session/:name' => 'tours#dismiss_session', :as => :dismiss_tour_session
  resources :users do |user|
    match 'masquerade'
    delete 'delete'
    add_files(user, :images => true)
    add_zip_file_imports(user)
    resources :page_views, :only => 'index'
    resources :folders do
      match 'download'
    end
    resources :calendar_events
    match 'external_tools/:id', :action => 'external_tool'
    resources :rubrics
    resources :rubric_associations do 
      match "invite"
      resources :rubric_assessments, :as => 'assessments'
    end
    resources :pseudonyms, :except => %w(index)
    resources :question_banks, :only => [:index]
    match 'assignments_needing_grading'
    match 'assignments_needing_submitting'
    get 'admin_merge'
    post 'merge'
    match 'grades'
    resources :user_notes
    match 'manageable_courses'
    match 'outcomes', :action => 'user_outcome_results'
    match 'teacher_activity/course/:course_id', :action => 'teacher_activity'
    match 'teacher_activity/student/:student_id', :action => 'teacher_activity'
    match 'media_download'
    resources :messages, :only => [:index, :create] do |message|
      get "html_message"
    end
    #match 'show_message_template'
    #match 'message_templates'

    resource :profile, :only => %w(show update) do
      member do
        put 'communication'
        get 'settings'
      end
      resources :pseudonyms, :except => %w(index)
      resources :tokens, :except => %w(index)
      match 'profile_pictures', :action => 'profile_pics'
      delete "user_services/:id" => "users#delete_user_service"
      post "user_services" => "users#create_user_service"
    end
    match 'about/:id' => 'profile#show', :as => :user_profile
  end

  resources :communication_channels
  resource :pseudonym_session

  # dashboard_url is / , not /dashboard
  get 'dashboard-sidebar' => 'users#dashboard_sidebar'
  post 'toggle_dashboard' => 'users#toggle_dashboard'
  get 'styleguide' => 'info#styleguide'
  get 'old_styleguide' => 'info#old_styleguide'
  # backwards compatibility with the old /dashboard url
  get 'dashboard' => 'users#user_dashboard', :as => :dashboard

  # Thought this idea of having dashboard-scoped urls was a good idea at the
  # time... now I'm not as big a fan.
  resource :dashboard, :only => [] do |dashboard|
    add_files(dashboard)
    delete 'account_notifications/:id', :action => 'close_notification'
    match "eportfolios" => "eportfolios#user_index"
    match "grades"
    resources :rubrics, :as => :assessments
    # comment_session can be removed once the iOS apps are no longer using it
    match "comment_session" => "services_api#start_kaltura_session"
    delete 'ignore_stream_item/:id', :action => 'ignore_stream_item'
  end

  resources :plugins, :only => [:index, :show, :update]

  get 'calendar' => 'calendars#show'
  get 'calendar2' => 'calendars#show2'
  get 'course_sections/:course_section_id/calendar_events/:id' => 'calendar_events#show'
  post 'switch_calendar/:preferred_calendar' => 'calendars#switch_calendar'
  get 'files' => 'files#full_index'
  match 'files/s3_success/:id' => 'files#s3_success'
  match 'files/:id/public_url.:format' => 'files#public_url'
  match 'files/preflight' => 'files#preflight'
  match 'files/pending' => 'files#create_pending'
  get 'assignments' => 'assignments#index'

  resources :appointment_groups, :only => [:index, :show]

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route ( HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  post "errors" => "info#record_error"
  get 'record_js_error' => 'info#record_js_error'
  resources :errors, :as => :error_reports, :only => [:show, :index]

  match "health_check" => 'info#health_check'

  match "facebook" => "facebook#index"
  match "facebook/message/:id" => "facebook#hide_message"
  match "facebook/settings" => "facebook#settings"
  match "facebook/notification_preferences" => "facebook#notification_preferences"

  resources :interaction_tests, :collection => {:next => :get, :register => :get, :groups => :post}

  post 'object_snippet' => 'context#object_snippet'
  match "saml_consume" => "pseudonym_sessions#saml_consume"
  match "saml_logout" => "pseudonym_sessions#saml_logout"
  match "saml_meta_data" => 'accounts#saml_meta_data'

  # Routes for course exports
  match 'xsd/:version.xsd' => 'content_exports#xml_schema'

  resources :jobs, :only => %w(index show), :collection => { :batch_update => :post }

  #Jammit::Routes.draw(map) if defined?(Jammit)

  ### API routes ###

  ApiRouteSet::V1.route(self) do |api|
    api.with_options(:controller => :courses) do |courses|
      get 'courses' => 'courses#index'
      post 'accounts/:account_id/courses' => 'courses#create'
      put 'courses/:id' => 'courses#update'
      get 'courses/:id' => 'courses#show'
      get 'courses/:course_id/students' => 'courses#students'
      get 'courses/:course_id/settings' => 'courses#settings', :path_name => 'course_settings'
      put 'courses/:course_id/settings' => 'courses#update_settings'
      get 'courses/:course_id/recent_students' => 'courses#recent_students', :path_name => 'course_recent_students'
      get 'courses/:course_id/users' => 'courses#users', :path_name => 'course_users'
      get 'courses/:course_id/users/:id' => 'courses#user', :path_name => 'course_user'
      get 'courses/:course_id/search_users' => 'courses#search_users', :path_name => 'course_search_users'
      get 'courses/:course_id/activity_stream' => 'courses#activity_stream', :path_name => 'course_activity_stream'
      get 'courses/:course_id/activity_stream/summary' => 'courses#activity_stream_summary', :path_name => 'course_activity_stream_summary'
      get 'courses/:course_id/todo' => 'courses#todo_items'
      delete 'courses/:id' => 'courses#destroy'
      post 'courses/:course_id/course_copy' => 'content_imports#copy_course_content'
      get 'courses/:course_id/course_copy/:id' => 'content_imports#copy_course_status', :path_name => :course_copy_status
      post 'courses/:course_id/files' => 'courses#create_file'
      post 'courses/:course_id/folders' => 'folders#create'
      get  'courses/:course_id/folders/:id' => 'folders#show', :path_name => 'course_folder'
      put  'accounts/:account_id/courses' => 'courses#batch_update'
    end

    api.with_options(:controller => :tabs) do |tabs|
      get "courses/:course_id/tabs" => 'tabs#index', :path_name => 'course_tabs'
      get "groups/:group_id/tabs" => 'tabs#index', :path_name => 'group_tabs'
    end

    api.with_options(:controller => :sections) do |sections|
      get 'courses/:course_id/sections' => 'tabs#index', :path_name => 'course_sections'
      get 'courses/:course_id/sections/:id' => 'tabs#show', :path_name => 'course_section'
      get 'sections/:id' => 'tabs#show'
      post 'courses/:course_id/sections' => 'tabs#create'
      put 'sections/:id' => 'tabs#update'
      delete 'sections/:id' => 'tabs#destroy'
      post 'sections/:id/crosslist/:new_course_id' => 'tabs#crosslist'
      delete 'sections/:id/crosslist' => 'tabs#uncrosslist'
    end

    api.with_options(:controller => :enrollments_api) do |enrollments|
      get  'courses/:course_id/enrollments' => 'enrollments_api#index', :path_name => 'course_enrollments'
      get  'sections/:section_id/enrollments'=> 'enrollments_api#index', :path_name => 'section_enrollments'
      get  'users/:user_id/enrollments' => 'enrollments_api#index', :path_name => 'user_enrollments'

      post 'courses/:course_id/enrollments' => 'enrollments_api#create'
      post 'sections/:section_id/enrollments' => 'enrollments_api#create'

      delete 'courses/:course_id/enrollments/:id' => 'enrollments_api#destroy'
    end

    api.with_options(:controller => :assignments_api) do |assignments|
      get 'courses/:course_id/assignments' => 'assignments_api#index', :path_name => 'course_assignments'
      get 'courses/:course_id/assignments/:id' => 'assignments_api#show', :path_name => 'course_assignment'
      post 'courses/:course_id/assignments' => 'assignments_api#create'
      put 'courses/:course_id/assignments/:id' => 'assignments_api#update'
      delete 'courses/:course_id/assignments/:id' => 'assignments_api#destroy', :controller => :assignments
    end

    api.with_options(:controller => :assignment_overrides) do |overrides|
      get 'courses/:course_id/assignments/:assignment_id/overrides' => 'assignment_overrides#index'
      post 'courses/:course_id/assignments/:assignment_id/overrides' => 'assignment_overrides#create'
      get 'courses/:course_id/assignments/:assignment_id/overrides/:id' => 'assignment_overrides#show', :path_name => 'assignment_override'
      put 'courses/:course_id/assignments/:assignment_id/overrides/:id' => 'assignment_overrides#update'
      delete 'courses/:course_id/assignments/:assignment_id/overrides/:id' => 'assignment_overrides#destroy'
      get 'sections/:course_section_id/assignments/:assignment_id/override' => 'assignment_overrides#section_alias'
      get 'groups/:group_id/assignments/:assignment_id/override' => 'assignment_overrides#group_alias'
    end

    api.with_options(:controller => :submissions_api) do |submissions|
      def submissions_api(submissions, context)
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions" => 'submissions_api#index', :path_name => "#{context}_assignment_submissions"
        get "#{context.pluralize}/:#{context}_id/students/submissions" => 'submissions_api#for_students', :path_name => "#{context}_student_submissions"
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id" => 'submissions_api#show', :path_name => "#{context}_assignment_submission"
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions" => 'submissions#create'
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/files" => 'submissions_api#create_file'
        put "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id" => 'submissions_api#update', :path_name => "#{context}_assignment_submission"
      end
      submissions_api(submissions, "course")
      submissions_api(submissions, "section")
    end

    api.with_options(:controller => :gradebook_history_api) do |gradebook_history|
      get "courses/:course_id/gradebook_history/days" => 'gradebook_history_api#days', :path_name => 'gradebook_history'
      get "courses/:course_id/gradebook_history/feed" => 'gradebook_history_api#feed', :path_name => 'gradebook_history_feed'
      get "courses/:course_id/gradebook_history/:date" => 'gradebook_history_api#day_details', :path_name => 'gradebook_history_for_day'
      get "courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions" => 'gradebook_history_api#submissions', :path_name => 'gradebook_history_submissions'
    end

    #api.get 'courses/:course_id/assignment_groups' => 'assignment_groups#index', :path_name => 'course_assignment_groups'
    api.with_options(:controller => :assignment_groups_api) do |ag|
      resources :assignment_groups, :path_prefix => "courses/:course_id", :name_prefix => "course_", :except => [:index]
    end

    api.with_options(:controller => :discussion_topics) do |topics|
      get 'courses/:course_id/discussion_topics' => 'discussion_topics#index', :path_name => 'course_discussion_topics'
      get 'groups/:group_id/discussion_topics' => 'discussion_topics#index', :path_name => 'group_discussion_topics'
    end

    api.with_options(:controller => :content_migrations) do |cm|
      get 'courses/:course_id/content_migrations/migrators' => 'content_migrations#available_migrators', :path_name => 'course_content_migration_migrators_list'
      get 'courses/:course_id/content_migrations/:id' => 'content_migrations#show', :path_name => 'course_content_migration'
      get 'courses/:course_id/content_migrations' => 'content_migrations#index', :path_name => 'course_content_migration_list'
      post 'courses/:course_id/content_migrations' => 'content_migrations#create', :path_name => 'course_content_migration_create'
      put 'courses/:course_id/content_migrations/:id' => 'content_migrations#update', :path_name => 'course_content_migration_update'
      get 'courses/:course_id/content_migrations/:id/selective_data' => 'content_migrations#content_list', :path_name => 'course_content_migration_selective_data'
    end

    api.with_options(:controller => :migration_issues) do |mi|
      get 'courses/:course_id/content_migrations/:content_migration_id/migration_issues/:id' => 'migration_issues#show', :path_name => 'course_content_migration_migration_issue'
      get 'courses/:course_id/content_migrations/:content_migration_id/migration_issues' => 'migration_issues#index', :path_name => 'course_content_migration_migration_issue_list'
      post 'courses/:course_id/content_migrations/:content_migration_id/migration_issues' => 'migration_issues#create', :path_name => 'course_content_migration_migration_issue_create'
      put 'courses/:course_id/content_migrations/:content_migration_id/migration_issues/:id' => 'migration_issues#update', :path_name => 'course_content_migration_migration_issue_update'
    end

    api.with_options(:controller => :discussion_topics_api) do |topics|
      def topic_routes(topics, context)
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id" => 'discussion_topics_api#show', :path_name => "#{context}_discussion_topic"
        post "#{context.pluralize}/:#{context}_id/discussion_topics" => 'discussion_topics#create'
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id" => 'discussion_topics#update'
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id" => 'discussion_topics#destroy'

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/view" => 'discussion_topics_api#view', :path_name => "#{context}_discussion_topic_view"

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entry_list" => 'discussion_topics_api#entry_list', :path_name => "#{context}_discussion_topic_entry_list"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries" => 'discussion_topics_api#add_entry', :path_name => "#{context}_discussion_add_entry"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries" => 'discussion_topics_api#entries', :path_name => "#{context}_discussion_entries"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies" => 'discussion_topics_api#add_reply', :path_name => "#{context}_discussion_add_reply"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies" => 'discussion_topics_api#replies', :path_name => "#{context}_discussion_replies"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id" => 'discussion_entries#update', :path_name => "#{context}_discussion_update_reply"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id" => 'discussion_entries#destroy', :path_name => "#{context}_discussion_delete_reply"

        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read" => 'discussion_topics_api#mark_topic_read', :path_name => "#{context}_discussion_topic_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read" => 'discussion_topics_api#mark_topic_unread', :path_name => "#{context}_discussion_topic_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all" => 'discussion_topics_api#mark_all_read', :path_name => "#{context}_discussion_topic_mark_all_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all" => 'discussion_topics_api#mark_all_unread', :path_name => "#{context}_discussion_topic_mark_all_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read" => 'discussion_topics_api#mark_entry_read', :path_name => "#{context}_discussion_topic_discussion_entry_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read" => 'discussion_topics_api#mark_entry_unread', :path_name => "#{context}_discussion_topic_discussion_entry_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed" => 'discussion_topics_api#subscribe_topic', :path_name => "#{context}_discussion_topic_subscribe"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed" => 'discussion_topics_api#unsubscribe_topic', :path_name => "#{context}_discussion_topic_unsubscribe"
      end
      topic_routes(topics, "course")
      topic_routes(topics, "group")
      topic_routes(topics, "collection_item")
    end

    api.with_options(:controller => :collaborations) do |collaborations|
      get 'collaborations/:id/members' => 'collaborations#members', :path_name => 'collaboration_members'
    end

    api.with_options(:controller => :external_tools) do |tools|
      def et_routes(route_object, context)
        get "#{context}s/:#{context}_id/external_tools/sessionless_launch" => 'external_tools#generate_sessionless_launch', :path_name => "#{context}_external_tool_sessionless_launch"
        get "#{context}s/:#{context}_id/external_tools/:external_tool_id" => 'external_tools#show', :path_name => "#{context}_external_tool_show"
        get "#{context}s/:#{context}_id/external_tools" => 'external_tools#index', :path_name => "#{context}_external_tools"
        post "#{context}s/:#{context}_id/external_tools" => 'external_tools#create', :path_name => "#{context}_external_tools_create"
        put "#{context}s/:#{context}_id/external_tools/:external_tool_id" => 'external_tools#update', :path_name => "#{context}_external_tools_update"
        delete "#{context}s/:#{context}_id/external_tools/:external_tool_id" => 'external_tools#destroy', :path_name => "#{context}_external_tools_delete"
      end
      et_routes(tools, "course")
      et_routes(tools, "account")
    end

    api.with_options(:controller => :external_feeds) do |feeds|
      def ef_routes(route_object, context)
        get "#{context}s/:#{context}_id/external_feeds" => 'external_feeds#index', :path_name => "#{context}_external_feeds"
        post "#{context}s/:#{context}_id/external_feeds" => 'external_feeds#create', :path_name => "#{context}_external_feeds_create"
        delete "#{context}s/:#{context}_id/external_feeds/:external_feed_id" => 'external_feeds#destroy', :path_name => "#{context}_external_feeds_delete"
      end
      ef_routes(feeds, "course")
      ef_routes(feeds, "group")
    end

    api.with_options(:controller => :sis_imports_api) do |sis|
      post 'accounts/:account_id/sis_imports' => 'sis_imports_api#create'
      get 'accounts/:account_id/sis_imports/:id' => 'sis_imports_api#show'
    end

    api.with_options(:controller => :users) do |users|
      get 'users/self/activity_stream' => 'users#activity_stream', :path_name => 'user_activity_stream'
      get 'users/activity_stream' => 'users#activity_stream' # deprecated
      get 'users/self/activity_stream/summary' => 'users#activity_stream_summary', :path_name => 'user_activity_stream_summary'

      put "users/:user_id/followers/self" => 'users#follow'
      delete "users/:user_id/followers/self" => 'users#unfollow'

      get 'users/self/todo' => 'users#todo_items'
      get 'users/self/upcoming_events' => 'users#upcoming_events'

      delete 'users/self/todo/:asset_string/:purpose' => 'users#ignore_item', :path_name => 'users_todo_ignore'
      post 'accounts/:account_id/users' => 'users#create'
      get 'accounts/:account_id/users' => 'users#index', :path_name => 'account_users'
      delete 'accounts/:account_id/users/:id' => 'users#destroy'

      put 'users/:id' => 'users#update'
      post 'users/:user_id/files' => 'users#create_file'

      post 'users/:user_id/folders' => 'folders#create'
      get 'users/:user_id/folders/:id' => 'folders#show', :path_name => 'user_folder'

      get 'users/:id/settings' => 'users#settings'
      put 'users/:id/settings' => 'users#settings', path_name: 'user_settings'
    end

    api.with_options(:controller => :pseudonyms) do |pseudonyms|
      get 'accounts/:account_id/logins' => 'pseudonyms#index', :path_name => 'account_pseudonyms'
      get 'users/:user_id/logins' => 'pseudonyms#index', :path_name => 'user_pseudonyms'
      post 'accounts/:account_id/logins' => 'pseudonyms#create'
      put 'accounts/:account_id/logins/:id' => 'pseudonyms#update'
      delete 'users/:user_id/logins/:id' => 'pseudonyms#destroy'
    end

    api.with_options(:controller => :accounts) do |accounts|
      get 'accounts' => 'accounts#index', :path_name => :accounts
      get 'accounts/:id' => 'accounts#show'
      put 'accounts/:id' => 'accounts#update'
      get 'accounts/:account_id/courses' => 'accounts#courses_api', :path_name => 'account_courses'
      get 'accounts/:account_id/sub_accounts' => 'accounts#sub_accounts', :path_name => 'sub_accounts'
      get 'accounts/:account_id/courses/:id' => 'courses#show', :path_name => 'account_course_show'
    end

    api.with_options(:controller => :role_overrides) do |roles|
      get 'accounts/:account_id/roles' => 'role_overrides#api_index', :path_name => 'account_roles'
      get 'accounts/:account_id/roles/:role' => 'role_overrides#show', :role => /[^\/]+/ 
      post 'accounts/:account_id/roles' => 'role_overrides#add_role'
      post 'accounts/:account_id/roles/:role/activate' => 'role_overrides#activate_role', :role => /[^\/]+/
      put 'accounts/:account_id/roles/:role' => 'role_overrides#update', :role => /[^\/]+/
      delete 'accounts/:account_id/roles/:role' => 'role_overrides#remove_role', :role => /[^\/]+/
    end

    api.with_options(:controller => :account_reports) do |reports|
      get 'accounts/:account_id/reports/:report' => 'account_reports#index'
      get 'accounts/:account_id/reports' => 'account_reports#available_reports'
      get 'accounts/:account_id/reports/:report/:id' => 'account_reports#show'
      post 'accounts/:account_id/reports/:report' => 'account_reports#create'
      delete 'accounts/:account_id/reports/:report/:id' => 'account_reports#destroy'
    end

    api.with_options(:controller => :admins) do |admins|
      post 'accounts/:account_id/admins' => 'admins#create'
      delete 'accounts/:account_id/admins/:user_id' => 'admins#destroy'
      get 'accounts/:account_id/admins' => 'admins#index', :path_name => 'account_admins'
    end

    api.with_options(:controller => :account_authorization_configs) do |authorization_configs|
      get 'accounts/:account_id/account_authorization_configs/discovery_url' => 'account_authorization_configs#show_discovery_url'
      put 'accounts/:account_id/account_authorization_configs/discovery_url' => 'account_authorization_configs#update_discovery_url', :path_name => 'account_update_discovery_url'
      delete 'accounts/:account_id/account_authorization_configs/discovery_url' => 'account_authorization_configs#destroy_discovery_url', :path_name => 'account_destroy_discovery_url'

      get 'accounts/:account_id/account_authorization_configs' => 'account_authorization_configs#index'
      get 'accounts/:account_id/account_authorization_configs/:id' => 'account_authorization_configs#show'
      post 'accounts/:account_id/account_authorization_configs' => 'account_authorization_configs#create', :path_name => 'account_create_aac'
      put 'accounts/:account_id/account_authorization_configs/:id' => 'account_authorization_configs#update', :path_name => 'account_update_aac'
      delete 'accounts/:account_id/account_authorization_configs/:id' => 'account_authorization_configs#destroy', :path_name => 'account_delete_aac'
    end

    get 'users/:user_id/page_views' => 'page_views#index', :path_name => 'user_page_views'
    get 'users/:user_id/profile' => 'profile#settings'
    get 'users/:user_id/avatars' => 'profile#profile_pics'

    # deprecated routes, second one is solely for YARD. preferred API is api/v1/search/recipients
    get 'conversations/find_recipients' => 'search#recipients'
    get 'conversations/find_recipients' => 'conversations#find_recipients'

    api.with_options(:controller => :conversations) do |conversations|
      get 'conversations' => 'conversations#index', :path_name => 'conversations'
      post 'conversations' => 'conversations#create'
      post 'conversations/mark_all_as_read' => 'conversations#mark_all_as_read'
      get 'conversations/batches' => 'conversations#batches', :path_name => 'conversations_batches'
      get 'conversations/unread_count' => 'conversations#unread_count'
      get 'conversations/:id' => 'conversations#show'
      put 'conversations/:id' => 'conversations#update' # stars, subscribed-ness, workflow_state
      delete 'conversations/:id' => 'conversations#destroy'
      post 'conversations/:id/add_message' => 'conversations#add_message'
      post 'conversations/:id/add_recipients' => 'conversations#add_recipients'
      post 'conversations/:id/remove_messages' => 'conversations#remove_messages'
      put 'conversations' => 'conversations#batch_update'
      delete 'conversations/:id/delete_for_all' => 'conversations#delete_for_all'
    end

    api.with_options(:controller => :communication_channels) do |channels|
      get 'users/:user_id/communication_channels' => 'communication_channels#index', :path_name => 'communication_channels'
      post 'users/:user_id/communication_channels' => 'communication_channels#create'
      delete 'users/:user_id/communication_channels/:id' => 'communication_channels#destroy'
    end

    api.with_options(:controller => :comm_messages_api) do |comm_messages|
      get 'comm_messages' => 'comm_messages_api#index', :path_name => 'comm_messages'
    end

    api.with_options(:controller => :services_api) do |services|
      get 'services/kaltura' => 'services_api#show_kaltura_config'
      post 'services/kaltura_session' => 'services_api#start_kaltura_session'
    end

    api.with_options(:controller => :calendar_events_api) do |events|
      get 'calendar_events' => 'calendar_events_api#index', :path_name => 'calendar_events'
      post 'calendar_events' => 'calendar_events_api#create'
      get 'calendar_events/:id' => 'calendar_events_api#show', :path_name => 'calendar_event'
      put 'calendar_events/:id' => 'calendar_events_api#update'
      delete 'calendar_events/:id' => 'calendar_events_api#destroy'
      post 'calendar_events/:id/reservations' => 'calendar_events_api#reserve'
      post 'calendar_events/:id/reservations/:participant_id' => 'calendar_events_api#reserve', :path_name => 'calendar_event_reserve'
    end

    api.with_options(:controller => :appointment_groups) do |appt_groups|
      get 'appointment_groups' => 'appointment_groups#index', :path_name => 'appointment_groups'
      post 'appointment_groups' => 'appointment_groups#create'
      get 'appointment_groups/:id' => 'appointment_groups#show', :path_name => 'appointment_group'
      put 'appointment_groups/:id' => 'appointment_groups#update'
      delete 'appointment_groups/:id' => 'appointment_groups#destroy'
      get 'appointment_groups/:id/users' => 'appointment_groups#users', :path_name => 'appointment_group_users'
      get 'appointment_groups/:id/groups' => 'appointment_groups#groups', :path_name => 'appointment_group_groups'
    end

    api.with_options(:controller => :groups) do |groups|
      resources :groups, :except => [:index]
      get 'users/self/groups' => 'groups#index', :path_name => "current_user_groups"
      get 'accounts/:account_id/groups' => 'groups#context_index', :path_name => 'account_user_groups'
      get 'courses/:course_id/groups' => 'groups#context_index', :path_name => 'course_user_groups'
      get 'groups/:group_id/users' => 'groups#users', :path_name => 'group_users'
      post 'groups/:group_id/invite' => 'groups#invite'
      post 'groups/:group_id/files' => 'groups#create_file'
      post 'group_categories/:group_category_id/groups' => 'groups#create'
      get 'groups/:group_id/activity_stream' => 'groups#activity_stream', :path_name => 'group_activity_stream'
      get 'groups/:group_id/activity_stream/summary' => 'groups#activity_stream_summary', :path_name => 'group_activity_stream_summary'
      put "groups/:group_id/followers/self" => 'groups#follow'
      delete "groups/:group_id/followers/self" => 'groups#unfollow'

      with_options(:controller => :group_memberships) do |memberships|
        resources :memberships, :path_prefix => "groups/:group_id", :name_prefix => "group_", :controller => :group_memberships, :except => [:show]
      end

      post 'groups/:group_id/folders' => 'folders#create'
      get 'groups/:group_id/folders/:id' => 'folders#show', :path_name => 'group_folder'
    end

    api.with_options(:controller => :collections) do |collections|
      get "collections" => 'collections#list', :path_name => 'collections'
      resources :collections, :path_prefix => "users/:user_id", :name_prefix => "user_", :only => [:index, :create]
      resources :collections, :path_prefix => "groups/:group_id", :name_prefix => "group_", :only => [:index, :create]
      resources :collections, :except => [:index, :create]
      put "collections/:collection_id/followers/self" => 'collections#follow'
      delete "collections/:collection_id/followers/self" => 'collections#unfollow'

      with_options(:controller => :collection_items) do |items|
        get "collections/:collection_id/items" => 'collection_items#index', :path_name => 'collection_items_list'
        resources :items, :path_prefix => "collections/:collection_id", :name_prefix => "collection_", :controller => :collection_items, :only => [:index, :create]
        resources :items, :path_prefix => "collections", :name_prefix => "collection_", :controller => :collection_items, :except => [:index, :create]
        put "collections/items/:item_id/upvotes/self" => 'collection_items#upvote'
        delete "collections/items/:item_id/upvotes/self" => 'collection_items#remove_upvote'
      end
    end

    api.with_options(:controller => :developer_keys) do |keys|
      get 'developer_keys' => 'developer_keys#index'
      get 'developer_keys/:id' => 'developer_keys#show'
      delete 'developer_keys/:id' => 'developer_keys#destroy'
      put 'developer_keys/:id' => 'developer_keys#update'
      post 'developer_keys' => 'developer_keys#create'
    end

    api.with_options(:controller => :search) do |search|
      get 'search/rubrics' => 'search#rubrics', :path_name => 'search_rubrics'
      get 'search/recipients' => 'search#recipients', :path_name => 'search_recipients'
    end

    post 'files/:id/create_success' => 'files#api_create_success', :path_name => 'files_create_success'
    get 'files/:id/create_success' => 'files#api_create_success', :path_name => 'files_create_success'

    api.with_options(:controller => :files) do |files|
      post 'files/:id/create_success' => 'files#api_create_success', :path_name => 'files_create_success'
      get 'files/:id/create_success' => 'files#api_create_success', :path_name => 'files_create_success'
      # 'attachment' (rather than 'file') is used below so modules API can use polymorphic_url to generate an item API link
      get 'files/:id' => 'files#api_show', :path_name => 'attachment'
      delete 'files/:id' => 'files#destroy'
      put 'files/:id' => 'files#api_update'
      get 'files/:id/:uuid/status' => 'files#api_file_status', :path_name => 'file_status'
    end

    api.with_options(:controller => :folders) do |folders|
      get 'folders/:id' => 'folders#show'
      get 'folders/:id/folders' => 'folders#api_index', :path_name => 'list_folders'
      get 'folders/:id/files' => 'files#api_index', :path_name => 'list_files'
      delete 'folders/:id' => 'folders#api_destroy'
      put 'folders/:id' => 'folders#update'
      post 'folders/:folder_id/folders' => 'folders#create', :path_name => 'create_folder'
      post 'folders/:folder_id/files' => 'folders#create_file'
    end

    api.with_options(:controller => :favorites) do |favorites|
      get "users/self/favorites/courses" => 'favorites#list_favorite_courses', :path_name => :list_favorite_courses
      post "users/self/favorites/courses/:id" => 'favorites#add_favorite_course'
      delete "users/self/favorites/courses/:id" => 'favorites#remove_favorite_course'
      delete "users/self/favorites/courses" => 'favorites#reset_course_favorites'
    end

    api.with_options(:controller => :wiki_pages_api) do |wiki_pages|
      get "courses/:course_id/pages" => 'wiki_pages_api#index', :path_name => 'course_wiki_pages'
      get "groups/:group_id/pages" => 'wiki_pages_api#index', :path_name => 'group_wiki_pages'
      get "courses/:course_id/pages/:url" => 'wiki_pages_api#show', :path_name => 'course_wiki_page'
      get "groups/:group_id/pages/:url" => 'wiki_pages_api#show', :path_name => 'group_wiki_page'
      get "courses/:course_id/front_page" => 'wiki_pages_api#show'
      get "groups/:group_id/front_page" => 'wiki_pages_api#show'
      post "courses/:course_id/pages" => 'wiki_pages_api#create'
      post "groups/:group_id/pages" => 'wiki_pages_api#create'
      put "courses/:course_id/pages/:url" => 'wiki_pages_api#update'
      put "groups/:group_id/pages/:url" => 'wiki_pages_api#update'
      put "courses/:course_id/front_page" => 'wiki_pages_api#update'
      put "groups/:group_id/front_page" => 'wiki_pages_api#update'
      delete "courses/:course_id/pages/:url" => 'wiki_pages_api#destroy'
      delete "groups/:group_id/pages/:url" => 'wiki_pages_api#destroy'
      delete "courses/:course_id/front_page" => 'wiki_pages_api#destroy'
      delete "groups/:group_id/front_page" => 'wiki_pages_api#destroy'
    end

    api.with_options(:controller => :context_modules_api) do |context_modules|
      get "courses/:course_id/modules" => 'context_modules_api#index', :path_name => 'course_context_modules'
      get "courses/:course_id/modules/:id" => 'context_modules_api#show', :path_name => 'course_context_module'
      put "courses/:course_id/modules" => 'context_modules_api#batch_update'
      post "courses/:course_id/modules" => 'context_modules_api#create', :path_name => 'course_context_module_create'
      put "courses/:course_id/modules/:id" => 'context_modules_api#update', :path_name => 'course_context_module_update'
      delete "courses/:course_id/modules/:id" => 'context_modules_api#destroy'
    end

    api.with_options(:controller => :context_module_items_api) do |context_module_items|
      get "courses/:course_id/modules/:module_id/items" => 'context_module_items_api#index', :path_name => 'course_context_module_items'
      get "courses/:course_id/modules/:module_id/items/:id" => 'context_module_items_api#show', :path_name => 'course_context_module_item'
      get "courses/:course_id/module_item_redirect/:id" => 'context_module_items_api#redirect', :path_name => 'course_context_module_item_redirect'
      post "courses/:course_id/modules/:module_id/items" => 'context_module_items_api#create', :path_name => 'course_context_module_items_create'
      put "courses/:course_id/modules/:module_id/items/:id" => 'context_module_items_api#update', :path_name => 'course_context_module_item_update'
      delete "courses/:course_id/modules/:module_id/items/:id" => 'context_module_items_api#destroy'
    end

    api.with_options(:controller => :quizzes_api) do |quizzes|
      get "courses/:course_id/quizzes" => 'quizzes_api#index', :path_name => 'course_quizzes'
      post "courses/:course_id/quizzes" => 'quizzes_api#create', :path_name => 'course_quiz_create'
      get "courses/:course_id/quizzes/:id" => 'quizzes_api#show', :path_name => 'course_quiz'
      put "courses/:course_id/quizzes/:id" => 'quizzes_api#update', :path_name => 'course_quiz_update'
      delete "courses/:course_id/quizzes/:id" => 'quizzes_api#destroy',
        path_name: 'course_quiz_destroy'
    end

    api.with_options(:controller => :quiz_reports) do |statistics|
      post "courses/:course_id/quizzes/:quiz_id/reports" => 'quiz_reports#create', :path_name => 'course_quiz_reports_create'
      get "courses/:course_id/quizzes/:quiz_id/reports/:id" => 'quiz_reports#show', :path_name => 'course_quiz_report'
    end

    api.with_options(:controller => :quiz_submissions_api) do |quiz_submissions|
      post 'courses/:course_id/quizzes/:quiz_id/quiz_submissions/self/files' => 'quiz_submissions_api#create_file', :path_name => 'quiz_submission_create_file'
    end

    api.with_options(:controller => :outcome_groups_api) do |outcome_groups|
      def og_routes(route_object, context)
        prefix = (context == "global" ? context : "#{context}s/:#{context}_id")
        get "#{prefix}/root_outcome_group" => 'outcome_groups_api#redirect', :path_name => "#{context}_redirect"
        get "#{prefix}/outcome_groups/account_chain" => 'outcome_groups_api#account_chain', :path_name => "#{context}_account_chain"
        get "#{prefix}/outcome_groups/:id" => 'outcome_groups_api#show', :path_name => "#{context}_outcome_group"
        put "#{prefix}/outcome_groups/:id" => 'outcome_groups_api#update'
        delete "#{prefix}/outcome_groups/:id" => 'outcome_groups_api#destroy'
        get "#{prefix}/outcome_groups/:id/outcomes" => 'outcome_groups_api#outcomes', :path_name => "#{context}_outcome_group_outcomes"
        get "#{prefix}/outcome_groups/:id/available_outcomes" => 'outcome_groups_api#available_outcomes', :path_name => "#{context}_outcome_group_available_outcomes"
        post "#{prefix}/outcome_groups/:id/outcomes" => 'outcome_groups_api#link'
        put "#{prefix}/outcome_groups/:id/outcomes/:outcome_id" => 'outcome_groups_api#link', :path_name => "#{context}_outcome_link"
        delete "#{prefix}/outcome_groups/:id/outcomes/:outcome_id" => 'outcome_groups_api#unlink'
        get "#{prefix}/outcome_groups/:id/subgroups" => 'outcome_groups_api#subgroups', :path_name => "#{context}_outcome_group_subgroups"
        post "#{prefix}/outcome_groups/:id/subgroups" => 'outcome_groups_api#create'
        post "#{prefix}/outcome_groups/:id/import" => 'outcome_groups_api#import', :path_name => "#{context}_outcome_group_import"
        post "#{prefix}/outcome_groups/:id/batch" => 'outcome_groups_api#batch', :path_name => "#{context}_outcome_group_batch"
      end

      og_routes(outcome_groups, 'global')
      og_routes(outcome_groups, 'account')
      og_routes(outcome_groups, 'course')
    end

    api.with_options(:controller => :outcomes_api) do |outcomes|
      get "outcomes/:id" => 'outcomes_api#show', :path_name => "outcome"
      put "outcomes/:id" => 'outcomes_api#update'
      delete "outcomes/:id" => 'outcomes_api#destroy'
    end

    api.with_options(:controller => :group_categories) do |group_categories|
      resources :group_categories, :except => [:index, :create]
      get 'accounts/:account_id/group_categories' => 'group_categories#index', :path_name => 'account_group_categories'
      get 'courses/:course_id/group_categories' => 'group_categories#index', :path_name => 'course_group_categories'
      post 'accounts/:account_id/group_categories' => 'group_categories#create'
      post 'courses/:course_id/group_categories' => 'group_categories#create'
      get 'group_categories/:group_category_id/groups' => 'group_categories#groups', :path_name => 'group_category_groups'
      get 'group_categories/:group_category_id/users' => 'group_categories#users', :path_name => 'group_category_users'
    end

    api.with_options(:controller => :progress) do |progress|
      get "progress/:id" => 'progress#show', :path_name => "progress"
    end

    api.with_options(:controller => :app_center) do |app_center|
      ['course', 'account'].each do |context|
        prefix = "#{context}s/:#{context}_id/app_center"
        get  "#{prefix}/apps" => 'app_center#index',   :path_name => "#{context}_app_center_apps"
        get  "#{prefix}/apps/:app_id/reviews" => 'app_center#reviews', :path_name => "#{context}_app_center_app_reviews"
        get  "#{prefix}/apps/:app_id/reviews/self" => 'app_center#review',  :path_name => "#{context}_app_center_app_review"
        post "#{prefix}/apps/:app_id/reviews/self" => 'app_center#add_review'
      end
    end
  end

  # this is not a "normal" api endpoint in the sense that it is not documented
  # or called directly, it's used as the redirect in the file upload process
  # for local files. it also doesn't use the normal oauth authentication
  # system, so we can't put it in the api uri namespace.
  post 'files_api' => 'files#api_create'

  get 'login/oauth2/auth' => 'pseudonym_sessions#oauth2_auth'
  post 'login/oauth2/token' => 'pseudonym_sessions#oauth2_token'
  get 'login/oauth2/confirm' => 'pseudonym_sessions#oauth2_confirm'
  post 'login/oauth2/accept' => 'pseudonym_sessions#oauth2_accept'
  get 'login/oauth2/deny' => 'pseudonym_sessions#oauth2_deny'
  delete 'login/oauth2/token' => 'pseudonym_sessions#oauth2_logout'

  #ApiRouteSet.route(nil, "/api/lti/v1") do |lti|
    #post "tools/:tool_id/grade_passback" => 'lti_api#grade_passback', :path_name => "lti_grade_passback_api"
    #post "tools/:tool_id/ext_grade_passback" => 'lti_api#legacy_grade_passback', :path_name => "blti_legacy_grade_passback_api"
  #end

  match 'equation_images/:id' => 'equation_images#show', :id => /.+/

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  resources :assignments, :only => %w(index show)

  resources :files do |file|
    match 'download' => 'files#show', :download => '1'
  end

  resources :developer_keys, :only => [:index]

  resources :rubrics do |rubric|
    resources :rubric_assessments, :as => 'assessments'
  end
  match 'selection_test' => 'external_content#selection_test'

  resources :quiz_submissions do |submission|
    add_files(submission)
  end

  # commenting out all collection urls until collections are live
  # resources :collection_items, :only => [:new]
  # get_bookmarklet 'get_bookmarklet', :controller => 'collection_items', :action => 'get_bookmarklet'
  post 'collection_items/link_data' => 'collection_items#link_data'
  #
  # resources :collections, :only => [:show, :index] do |collection|
  #   collection.resources :collection_items, :only => [:show, :index]
  # end
  #root :to => :dashboard
  root :to => 'users#user_dashboard', :as => :dashboard
  # See how all your routes lay out with "rake routes"
end
