helpers do
  def protected!
    return if authorized?
    redirect '/login'
  end

  def authorized?
    if session['token'].nil?
      true
    else 
      false
    end
  end

  def create_session user_id, token
    session['user_count'] = JWT.encode('0', nil, 'none')
    session['number'] = JWT.encode('0', nil ,'none')
    session['user'] = JWT.encode(user_id.to_s, nil, 'none')
    session['token'] = JWT.encode(token.to_s, nil,'none')
  end

  def refresh_step
    session['user_count'] = JWT.encode('0', nil, 'none')
    session['number'] = JWT.encode('0', nil ,'none')
  end

  def destroy_session
    session = nil
  end
end