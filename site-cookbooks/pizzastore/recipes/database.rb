
PIZZASTORE_DB_NAME_DEV = node['pizzastore']['database']['prefix'] + 'development'
PIZZASTORE_DB_HOST = node['pizzastore']['database']['host'] || '127.0.0.1'
PIZZASTORE_DB_PORT = node['pizzastore']['database']['port'] || 5432
PIZZASTORE_DB_USER = node['pizzastore']['database']['username'] || 'vagrant'
PIZZASTORE_DB_PASS = node['pizzastore']['database']['password'] || 'vagrant'

postgresql_connection_info = {
	:host      => PIZZASTORE_DB_HOST,
	:port      => PIZZASTORE_DB_PORT,
	:password  => node['postgresql']['password']['postgres']
}

# Create a postgresql user but grant no privileges
postgresql_database_user PIZZASTORE_DB_USER do
  connection postgresql_connection_info
  
  password   PIZZASTORE_DB_PASS
  
  action    :create
end

# create a postgresql database
postgresql_database PIZZASTORE_DB_NAME_DEV do
  connection postgresql_connection_info

  action 	:create
end

# Grant all privileges on all tables in foo db
postgresql_database_user PIZZASTORE_DB_USER do
  connection    postgresql_connection_info

  database_name PIZZASTORE_DB_NAME_DEV

  privileges    [:all]

  action    :grant
end


