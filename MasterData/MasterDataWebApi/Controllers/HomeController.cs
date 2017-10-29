using System;
using System.Web.Http;


namespace MasterDataWebApi.Controllers
{
    public class HomeController : ApiController
    {
        public HomeController()
        {
        }

       
        public IHttpActionResult GetById(long id){
            return Ok(2);
        }
    }
}
