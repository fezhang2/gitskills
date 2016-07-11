# Type1 :"standalone server"
# Monitor Steps
# 1.check input redis server address list
# 2.if list.size() not equal to 1,fail with error:"only 1 server exists"
# 3.Try connect to server address with 3 times retry
#  on failed 3 times ,test fail with Mct alert
# 4.Write test dat:key="mct_check_t1_${SEVER_ADDR_PROT}",val="uuid"
# 5.check response, on receive nothing or not "ok",test fail with MCT alert
# 6.complete all the test above,test success
import sys
import redis



def checkAddressList(inputList):
    l=len(inputList)
    if l>1:
        print('Only 1 server exists in standalone')
        return 2
    elif l==0:
        print('please input server address')
        return 2
    else:
        return 0

def connectCheck():
    for i in range(3):
        if r.ping():
            print('ping succeed')
            label=0
            break
        else:
            print('the times of i ping failed')
            label=2
    return label

def testData():
    r.set('mct_check_t1_${SEVER_ADDR_PROT}','uuid')
    if(r.get('mct_check_t1_${SEVER_ADDR_PROT}'))=='uuid':
        print('test data response is ok')
        return 0
    else:
        print('test fail')
        return 2

def cluster_status_role_check():
    info=r.info()
    if info['cluster_enabled']==0:
        print('cluster_enabled=0')
    else:
        print('cluster_enabled==1')
        return 2
    if info['role']=='master':
        print('role: master')
    else:
        print('role:%s'%info['role'])
        return 2
    return 0

if __name__ == '__main__':
    host=str(sys.argv[1])
    password=str(sys.argv[2])
    r = redis.Redis(host=host, port=6379, db=0, password=password)
    if checkAddressList([])==0:
        print('check the server address list success')
    else:
        sys.exit(2)
    # r = redis.Redis(host='10.225.3.253', port=6379, db=0,password="")

    if connectCheck()!=0:
        print('connect failed')
        sys.exit(2)
    if cluster_status_role_check() != 0:
        print('cluster status or role check failed')
        sys.exit(2)

    if testData()!=0:
        print('testData failed')
        sys.exit(2)

    print('success')
    sys.exit(0)

