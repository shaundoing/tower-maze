f = open('/etc/cloudflared/config.yml', 'r+')
c = f.read()
f.seek(0)
f.write(c.replace(
    '  - service: http_status:404',
    '  - hostname: tower-maze.purpleprawn.com\n    service: http://localhost:8765\n  - service: http_status:404'
))
f.truncate()
f.close()
print('done')
