using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace TestIngest
{
    public class ServiceInfo
    {
        public string Hostname { get; set; }

        public int Port { get; set; }

        public string IP { get; set; }

        public string GetUrl()
        {
            return $"http://{IP}:{Port}";
        }
    }
    
    public class ServiceInfoPool : IEnumerable<ServiceInfo>
    {
        private readonly ServiceInfo[] _infoes;

        public ServiceInfoPool(ServiceInfo[] infoes)
        {
            _infoes = infoes;
        }
        
        public IEnumerator<ServiceInfo> GetEnumerator()
        {
            return (IEnumerator<ServiceInfo>) _infoes.GetEnumerator();
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
        
        public ServiceInfo PickOneRandom()
        {
            if (!_infoes.Any()) return null;
            var rng = new Random();
            return _infoes[rng.Next(_infoes.Length)];
        }

        public ServiceInfo this[int key]
        {
            get => _infoes[key];
            set => _infoes[key] = value;
        }
    }
}